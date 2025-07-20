const { contextBridge, ipcRenderer } = require("electron");

contextBridge.exposeInMainWorld("api", {
  loadServices: () => ipcRenderer.invoke("load-services"),
  saveServices: (services) => ipcRenderer.invoke("save-services", services),
  runScript: (name) => ipcRenderer.invoke("run-script", name),
});
