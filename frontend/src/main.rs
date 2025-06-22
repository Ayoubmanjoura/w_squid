use eframe::egui;
use std::{collections::HashMap, fs, process::Command, sync::mpsc, thread};
use serde::{Deserialize, Serialize};

#[derive(Default, Serialize, Deserialize)]
struct MyApp {
    services: HashMap<String, bool>,
    output: String,
    active_tab: Tab,
    // Channel to receive async script run results
    rx: Option<mpsc::Receiver<ScriptResult>>,
}

#[derive(Copy, Clone, PartialEq)]
enum Tab {
    Optimizations,
    Services,
}

struct ScriptResult {
    script_name: String,
    success: bool,
    stdout: String,
    stderr: String,
}

impl MyApp {
    fn new() -> Self {
        let mut app = Self::default();
        app.load_services();
        app
    }

    fn load_services(&mut self) {
        let path = "backend/disable/services/service.yaml";
        match fs::read_to_string(path) {
            Ok(content) => match serde_yaml::from_str::<HashMap<String, bool>>(&content) {
                Ok(map) => {
                    self.services = map;
                    self.output = "✅ Services loaded.".to_string();
                }
                Err(e) => self.output = format!("❌ YAML parse error: {}", e),
            },
            Err(e) => self.output = format!("❌ Failed to read {}: {}", path, e),
        }
    }

    fn save_services(&self) {
        let path = "backend/disable/services/service.yaml";
        if let Ok(yaml) = serde_yaml::to_string(&self.services) {
            if let Err(e) = fs::write(path, yaml) {
                eprintln!("❌ Failed to write {}: {}", path, e);
            }
        } else {
            eprintln!("❌ Failed to serialize services to YAML");
        }
    }

    fn get_script_path(service: &str, enable: bool) -> Option<&'static str> {
        // Map your services to script paths
        match (service.to_lowercase().as_str(), enable) {
            ("ipv6", true) => Some("../../backend/enable/enable_ipv6.ps1"),
            ("ipv6", false) => Some("../../backend/disable/disable_ipv6.ps1"),

            ("offload", true) => Some("../../backend/enable/enable_offload.ps1"),
            ("offload", false) => Some("../../backend/disable/disable_offload.ps1"),

            ("tcp_tuning", true) => Some("../../backend/enable/enable_tcp_tuning.ps1"),
            ("tcp_tuning", false) => Some("../../backend/disable/disable_tcp_tuning.ps1"),

            _ => None,
        }
    }

    fn run_script_async(&mut self, script_path: String, script_name: String) {
        // Create channel for communication
        let (tx, rx) = mpsc::channel();
        self.rx = Some(rx);

        thread::spawn(move || {
            let output = Command::new("powershell")
                .args(["-NoProfile", "-ExecutionPolicy", "Bypass", "-File", &script_path])
                .output();

            let (success, stdout, stderr) = match output {
                Ok(out) => (
                    out.status.success(),
                    String::from_utf8_lossy(&out.stdout).to_string(),
                    String::from_utf8_lossy(&out.stderr).to_string(),
                ),
                Err(e) => (false, "".to_string(), format!("Failed to run script: {}", e)),
            };

            let result = ScriptResult {
                script_name,
                success,
                stdout,
                stderr,
            };

            let _ = tx.send(result);
        });
    }

    fn render_services_tab(&mut self, ui: &mut egui::Ui) {
        egui::ScrollArea::vertical().show(ui, |ui| {
            // Clone keys to avoid borrow conflicts
            let services = self.services.clone();

            for (service, enabled) in services {
                let mut toggled = enabled;
                if ui.checkbox(&mut toggled, &service).changed() {
                    self.services.insert(service.clone(), toggled);
                    self.save_services();

                    if let Some(script_path) = Self::get_script_path(&service, toggled) {
                        let action = if toggled { "Enable" } else { "Disable" };
                        self.run_script_async(script_path.to_string(), format!("{} {}", action, service));
                        self.output = format!("⌛ Running {} script...", action);
                    } else {
                        self.output = format!("⚠️ No script found for service '{}'", service);
                    }
                }
            }
        });
    }

    fn render_optimizations_tab(&mut self, ui: &mut egui::Ui) {
        if ui.button("⚡ Better Power Management").clicked() {
            self.run_script_async("../../backend/enable/powerplan.ps1".to_string(), "PowerPlan".to_string());
            self.output = "⌛ Running PowerPlan script...".to_string();
        }

        if ui.button("🗑 Clean Junk Files").clicked() {
            self.run_script_async("../../backend/enable/clean_up.ps1".to_string(), "CleanUp".to_string());
            self.output = "⌛ Running CleanUp script...".to_string();
        }

        if ui.button("💿 Drive Optimization").clicked() {
            self.run_script_async("../../backend/enable/drive_optimization.ps1".to_string(), "DriveOpt".to_string());
            self.output = "⌛ Running Drive Optimization script...".to_string();
        }
    }
}

impl eframe::App for MyApp {
    fn update(&mut self, ctx: &egui::Context, _frame: &mut eframe::Frame) {
        egui::CentralPanel::default().show(ctx, |ui| {
            ui.heading("🦑 W Squid");

            // Tab bar with selectable labels
            ui.horizontal(|ui| {
                if ui.selectable_label(self.active_tab == Tab::Optimizations, "🛠 Optimizations").clicked() {
                    self.active_tab = Tab::Optimizations;
                }
                if ui.selectable_label(self.active_tab == Tab::Services, "🧩 Services Toggle").clicked() {
                    self.active_tab = Tab::Services;
                }
            });

            ui.separator();

            match self.active_tab {
                Tab::Optimizations => self.render_optimizations_tab(ui),
                Tab::Services => self.render_services_tab(ui),
            }

            ui.separator();

            // Show output log
            ui.label(&self.output);

            // Check for async script results
            if let Some(rx) = &self.rx {
                if let Ok(result) = rx.try_recv() {
                    if result.success {
                        self.output = format!("✅ {} succeeded.\n\nSTDOUT:\n{}", result.script_name, result.stdout);
                    } else {
                        self.output = format!("❌ {} failed.\n\nSTDERR:\n{}", result.script_name, result.stderr);
                    }
                    ctx.request_repaint(); // Force UI update
                }
            }
        });
    }
}

fn main() -> Result<(), eframe::Error> {
    let options = eframe::NativeOptions::default();
    eframe::run_native("W Squid", options, Box::new(|_cc| Ok(Box::new(MyApp::new()))))
}
