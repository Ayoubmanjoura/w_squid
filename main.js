const { app, BrowserWindow, ipcMain } = require("electron");
const path = require("path");
const { execFile } = require("child_process");
const fs = require("fs");
const YAML = require("yaml");

const SERVICES_FILE = "D:/Projects/w_squid/backend/services/service.yaml";

let win;

function createWindow() {
  win = new BrowserWindow({
    width: 500,
    height: 600,
    webPreferences: {
      preload: path.join(__dirname, "preload.js"),
    },
  });

  win.loadFile("index.html");
}

app.whenReady().then(createWindow);

ipcMain.handle("load-services", async () => {
  try {
    const file = fs.readFileSync(SERVICES_FILE, "utf8");
    const services = YAML.parse(file);
    return { success: true, services: services || {} };
  } catch (e) {
    return { success: false, error: e.message };
  }
});

ipcMain.handle("save-services", async (event, services) => {
  try {
    const yamlStr = YAML.stringify(services);
    fs.writeFileSync(SERVICES_FILE, yamlStr, "utf8");
    return { success: true };
  } catch (e) {
    return { success: false, error: e.message };
  }
});

ipcMain.handle("run-script", async (event, scriptName) => {
  const scriptPath = `D:/Projects/w_squid/backend/${scriptName}.ps1`;

  return new Promise((resolve) => {
    execFile(
      "powershell",
      ["-NoProfile", "-ExecutionPolicy", "Bypass", "-File", scriptPath],
      (error, stdout, stderr) => {
        if (error) {
          resolve({
            success: false,
            output: `❌ ${scriptName} failed.\n\n${stderr || error.message}`,
          });
        } else {
          resolve({
            success: true,
            output: `✅ ${scriptName} succeeded.\n\n${stdout}`,
          });
        }
      }
    );
  });
});
