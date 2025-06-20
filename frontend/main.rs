use eframe::egui;
use std::{
    collections::HashMap,
    fs,
    process::Command,
};
use serde::{Deserialize, Serialize};

#[derive(Default, Serialize, Deserialize)]
struct MyApp {
    output: String,
    services: HashMap<String, bool>,
    show_services_tab: bool,
}

impl MyApp {
    fn load_services(&mut self) {
        let yaml_path = "backend/disable/services/service.yaml";

        match fs::read_to_string(yaml_path) {
            Ok(content) => {
                match serde_yaml::from_str::<HashMap<String, bool>>(&content) {
                    Ok(map) => {
                        self.services = map;
                        self.output = "✅ Services loaded.".into();
                    }
                    Err(e) => {
                        self.output = format!("❌ YAML parse error: {}", e);
                    }
                }
            }
            Err(e) => {
                self.output = format!("❌ Couldn't read services.yaml: {}", e);
            }
        }
    }

    fn save_services(&self) {
        let yaml_path = "backend/disable/services/service.yaml";

        match serde_yaml::to_string(&self.services) {
            Ok(yaml) => {
                if let Err(e) = fs::write(yaml_path, yaml) {
                    eprintln!("❌ Failed to write YAML: {}", e);
                }
            }
            Err(e) => {
                eprintln!("❌ Failed to convert to YAML: {}", e);
            }
        }
    }

    fn run_script(&mut self, script_path: &str, script_name: &str) {
        let output = Command::new("powershell")
            .args([
                "-NoProfile",
                "-ExecutionPolicy", "Bypass",
                "-File",
                script_path,
            ])
            .output();

        match output {
            Ok(output) => {
                let stdout = String::from_utf8_lossy(&output.stdout);
                let stderr = String::from_utf8_lossy(&output.stderr);

                let status = if output.status.success() {
                    "✅ Success"
                } else {
                    "❌ Failed"
                };

                let log_msg = format!(
                    "[{}] [{}] {}\nSTDOUT:\n{}\nSTDERR:\n{}\n---\n",
                    chrono::Local::now().format("%Y-%m-%d %H:%M:%S"),
                    script_name,
                    status,
                    stdout,
                    stderr
                );
                println!("{}", log_msg);

                if output.status.success() {
                    self.output = format!("✅ {} executed successfully.\n\nSTDOUT:\n{}", script_name, stdout);
                } else {
                    self.output = format!("❌ {} failed.\n\nSTDERR:\n{}", script_name, stderr);
                }
            }
            Err(e) => {
                self.output = format!("❌ Failed to run script: {}", e);
            }
        }
    }

    fn get_script_path(&self, service: &str, enabled: bool) -> Option<String> {
        let service = service.to_lowercase();
        if enabled {
            // Run enable scripts from backend/enable/
            match service.as_str() {
                "ipv6" => Some("backend/enable/enable_ipv6.ps1".to_string()),
                "offload" => Some("backend/enable/enable_offload.ps1".to_string()),
                "tcp_tuning" => Some("backend/enable/enable_tcp_tuning.ps1".to_string()),
                _ => None,
            }
        } else {
            // Run disable scripts from backend/disable/
            match service.as_str() {
                "ipv6" => Some("backend/disable/disable_ipv6.ps1".to_string()),
                "offload" => Some("backend/disable/disable_offload.ps1".to_string()),
                "tcp_tuning" => Some("backend/disable/disable_tcp_tuning.ps1".to_string()),
                _ => None,
            }
        }
    }

    fn render_service_toggles(&mut self, ui: &mut egui::Ui) {
        egui::ScrollArea::vertical().show(ui, |ui| {
            for (service, current_value) in self.services.clone().into_iter() {
                let mut val = current_value;
                if ui.checkbox(&mut val, &service).changed() {
                    self.services.insert(service.clone(), val);
                    self.save_services();

                    if let Some(script_path) = self.get_script_path(&service, val) {
                        let script_name = format!("{} {}", if val { "Enable" } else { "Disable" }, service);
                        self.run_script(&script_path, &script_name);
                    } else {
                        self.output = format!("⚠️ No script configured for {} {}", service, if val { "enable" } else { "disable" });
                    }
                }
            }
        });
    }
}

impl eframe::App for MyApp {
    fn update(&mut self, ctx: &egui::Context, _frame: &mut eframe::Frame) {
        egui::CentralPanel::default().show(ctx, |ui| {
            ui.heading("🦑 W Squid");

            ui.horizontal(|ui| {
                if ui.button("🛠 Optimizations").clicked() {
                    self.show_services_tab = false;
                }
                if ui.button("🧩 Services Toggle").clicked() {
                    self.load_services();
                    self.show_services_tab = true;
                }
            });

            ui.separator();

            if self.show_services_tab {
                self.render_service_toggles(ui);
            } else {
                if ui.button("⚡ Better Power Management").clicked() {
                    self.run_script("backend/enable/powerplan.ps1", "PowerPlan");
                }
                if ui.button("🗑 Clean Junk Files").clicked() {
                    self.run_script("backend/enable/clean_up.ps1", "CleanUp");
                }
                if ui.button("💿 Drive Optimization").clicked() {
                    self.run_script("backend/enable/drive_optimization.ps1", "DriveOpt");
                }
            }

            ui.separator();
            ui.label(&self.output);
        });
    }
}

fn main() -> Result<(), eframe::Error> {
    let options = eframe::NativeOptions::default();
    eframe::run_native("W Squid", options, Box::new(|_cc| Box::new(MyApp::default())))
}
