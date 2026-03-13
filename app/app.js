const express = require("express");
const {
  BlobServiceClient,
  StorageSharedKeyCredential,
  generateBlobSASQueryParameters,
  BlobSASPermissions,
} = require("@azure/storage-blob");

const app = express();
const PORT = Number(process.env.PORT) || 3000;
const API_KEY = process.env.BACKEND_API_KEY;

app.use(express.json({ limit: "10mb" }));

const connectionString = process.env.AZURE_STORAGE_CONNECTION_STRING;
if (!connectionString) {
  throw new Error("AZURE_STORAGE_CONNECTION_STRING est requis.");
}

const blobServiceClient = BlobServiceClient.fromConnectionString(connectionString);

const allowedContainers = (process.env.ALLOWED_CONTAINERS || "images,logs")
  .split(",")
  .map((c) => c.trim())
  .filter(Boolean);

function isContainerAllowed(containerName) {
  return allowedContainers.includes(containerName);
}

function requireApiKey(req, res, next) {
  if (!API_KEY) {
    return next();
  }

  const provided = req.header("x-api-key");
  if (!provided || provided !== API_KEY) {
    return res.status(401).json({ error: "API key invalide ou manquante." });
  }

  return next();
}

app.get("/", (req, res) => {
  res.json({
    status: "ok",
    message: "Backend Node.js opérationnel avec Azure Blob Storage",
    timestamp: new Date().toISOString(),
  });
});

app.get("/health", (req, res) => {
  res.json({
    status: "healthy",
    service: "nodejs-backend-tp",
    storage: "azure-blob",
  });
});

app.get("/files", requireApiKey, async (req, res) => {
  try {
    const container = req.query.container;
    if (!container) {
      return res.status(400).json({ error: "Paramètre 'container' requis." });
    }

    if (!isContainerAllowed(container)) {
      return res.status(403).json({ error: "Accès interdit à ce conteneur." });
    }

    const containerClient = blobServiceClient.getContainerClient(container);
    const files = [];

    for await (const blob of containerClient.listBlobsFlat()) {
      files.push({
        name: blob.name,
        size: blob.properties.contentLength || 0,
        contentType: blob.properties.contentType || "application/octet-stream",
        lastModified: blob.properties.lastModified || null,
      });
    }

    return res.json({ container, files });
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
});

app.get("/files/:container/:blobName", requireApiKey, async (req, res) => {
  try {
    const { container, blobName } = req.params;

    if (!isContainerAllowed(container)) {
      return res.status(403).json({ error: "Accès interdit à ce conteneur." });
    }

    const blobClient = blobServiceClient
      .getContainerClient(container)
      .getBlobClient(blobName);

    const exists = await blobClient.exists();
    if (!exists) {
      return res.status(404).json({ error: "Fichier introuvable." });
    }

    const downloadResponse = await blobClient.download();
    const chunks = [];

    for await (const chunk of downloadResponse.readableStreamBody) {
      chunks.push(chunk);
    }

    const fileBuffer = Buffer.concat(chunks);
    const contentType = downloadResponse.contentType || "application/octet-stream";

    res.setHeader("Content-Type", contentType);
    res.setHeader("Content-Length", fileBuffer.length);
    return res.send(fileBuffer);
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
});

app.post("/files/:container/:blobName", requireApiKey, async (req, res) => {
  try {
    const { container, blobName } = req.params;
    const { content, contentType = "application/octet-stream", metadata = {} } = req.body;

    if (!isContainerAllowed(container)) {
      return res.status(403).json({ error: "Accès interdit à ce conteneur." });
    }

    if (typeof content !== "string") {
      return res.status(400).json({ error: "Le champ 'content' (base64 ou texte) est requis." });
    }

    const containerClient = blobServiceClient.getContainerClient(container);
    await containerClient.createIfNotExists();

    const blockBlobClient = containerClient.getBlockBlobClient(blobName);
    const body = req.query.encoding === "base64" ? Buffer.from(content, "base64") : Buffer.from(content);

    await blockBlobClient.uploadData(body, {
      blobHTTPHeaders: { blobContentType: contentType },
      metadata,
    });

    return res.status(201).json({
      message: "Fichier écrit avec succès.",
      container,
      blobName,
      size: body.length,
    });
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
});

app.post("/files/:container/:blobName/sas", requireApiKey, async (req, res) => {
  try {
    const { container, blobName } = req.params;
    const { permissions = "r", expiresInMinutes = 30 } = req.body;

    if (!isContainerAllowed(container)) {
      return res.status(403).json({ error: "Accès interdit à ce conteneur." });
    }

    const accountName = process.env.AZURE_STORAGE_ACCOUNT_NAME;
    const accountKey = process.env.AZURE_STORAGE_ACCOUNT_KEY;

    if (!accountName || !accountKey) {
      return res.status(500).json({
        error: "AZURE_STORAGE_ACCOUNT_NAME et AZURE_STORAGE_ACCOUNT_KEY sont requis pour générer un SAS.",
      });
    }

    const sharedKeyCredential = new StorageSharedKeyCredential(accountName, accountKey);
    const expiresOn = new Date(Date.now() + Number(expiresInMinutes) * 60 * 1000);

    const sas = generateBlobSASQueryParameters(
      {
        containerName: container,
        blobName,
        permissions: BlobSASPermissions.parse(permissions),
        startsOn: new Date(Date.now() - 5 * 60 * 1000),
        expiresOn,
      },
      sharedKeyCredential
    ).toString();

    const sasUrl = `${blobServiceClient
      .getContainerClient(container)
      .getBlobClient(blobName).url}?${sas}`;

    return res.json({
      container,
      blobName,
      permissions,
      expiresOn: expiresOn.toISOString(),
      sasUrl,
    });
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
});

app.listen(PORT, "0.0.0.0", () => {
  console.log(`Serveur démarré sur http://0.0.0.0:${PORT}`);
});