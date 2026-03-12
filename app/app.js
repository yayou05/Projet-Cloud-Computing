const express = require("express");
const app = express();
const PORT = 3000;

app.use(express.json());

// Route principale
app.get("/", (req, res) => {
  res.json({
    status: "ok",
    message: "Backend Node.js opérationnel !",
    timestamp: new Date().toISOString(),
  });
});

// Route santé
app.get("/health", (req, res) => {
  res.json({
    status: "healthy",
    service: "nodejs-backend-tp",
  });
});

// Route exemple : liste de fichiers
app.get("/files", (req, res) => {
  res.json({
    files: [
      { name: "image1.png",   container: "images", size: "2MB"   },
      { name: "log_2024.txt", container: "logs",   size: "500KB" },
    ],
  });
});

// Démarrer le serveur
app.listen(PORT, "0.0.0.0", () => {
  console.log(`Serveur démarré sur http://0.0.0.0:${PORT}`);
});