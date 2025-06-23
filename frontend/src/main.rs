use eframe::egui;
use log::{error, info, warn};
use simplelog::*;
use std::{
    collections::HashMap,
    fs,
    path::{Path, PathBuf},
    process::Command,
    sync::mpsc,
    thread,
    time::Duration,
};

#[derive(Copy, Clone, PartialEq)]
enum Tab {
    Optimizations,
    Services,
}

impl Default for Tab {
    fn default() -> Self {
        Tab::Optimizations
    }
}

struct ScriptResult {
    script_name: String,
    success: bool,
    stdout: String,
    stderr: String,
}

#[derive(Default)]
struct MyApp {
    services: HashMap<String, bool>,
    output: String,
    active_tab: Tab,
    rx: Option<mpsc::Receiver<ScriptResult>>,
}

impl MyApp {
    fn new(ctx: &egui::Context) -> Self {
        let mut style = (*ctx.style()).clone();
        style.visuals.window_fill = egui::Color32::from_rgb(36, 36, 36);
        style.visuals.selection.bg_fill = egui::Color32::from_rgb(124, 127, 235);
        ctx.set_style(style);

        let mut app = Self::default();
        app.load_services();
        app
    }

    fn load_services(&mut self) {
        let path = Path::new("D:/Projects/w_squid/backend/services/service.yaml");
        match fs::read_to_string(path) {
            Ok(content) => match serde_yaml::from_str::<HashMap<String, bool>>(&content) {
                Ok(map) => {
                    self.services = map;
                    self.output = "✅ Services loaded.".into();
                    info!("Services loaded from {:?}", path);
                }
                Err(e) => {
                    let msg = format!("❌ YAML parse error: {}", e);
                    self.output = msg.clone();
                    error!("{}", msg);
                }
            },
            Err(e) => {
                let msg = format!("❌ Failed to read {}: {}", path.display(), e);
                self.output = msg.clone();
                error!("{}", msg);
            }
        }
    }

    fn save_services(&self) {
        let path = Path::new("D:/Projects/w_squid/backend/services/service.yaml");
        match serde_yaml::to_string(&self.services) {
            Ok(yaml) => {
                if let Err(e) = fs::write(path, yaml) {
                    error!("❌ Failed to write {}: {}", path.display(), e);
                } else {
                    info!("Services saved to {:?}", path);
                }
            }
            Err(e) => error!("❌ Failed to serialize services: {}", e),
        }
    }

fn run_script_async(&mut self, script_path: PathBuf, script_name: String) {
    info!("Launching script: {} -> {}", script_name, script_path.display());

    let (tx, rx) = mpsc::channel();
    self.rx = Some(rx);

    thread::spawn(move || {
        if !script_path.exists() {
            let msg = format!("❌ Script not found: {}", script_path.display());
            error!("{}", msg);
            let _ = tx.send(ScriptResult {
                script_name,
                success: false,
                stdout: String::new(),
                stderr: msg,
            });
            return;
        }

        let script_str = match script_path.to_str() {
            Some(s) => s,
            None => {
                let msg = "❌ Invalid script path (non-UTF8)".to_string();
                error!("{}", msg);
                let _ = tx.send(ScriptResult {
                    script_name,
                    success: false,
                    stdout: String::new(),
                    stderr: msg,
                });
                return;
            }
        };

        let output = Command::new("powershell")
            .args([
                "-NoProfile",
                "-ExecutionPolicy",
                "Bypass",
                "-File",
                script_str,
            ])
            .output();

        let (success, stdout, stderr) = match output {
            Ok(out) => (
                out.status.success(),
                String::from_utf8_lossy(&out.stdout).to_string(),
                String::from_utf8_lossy(&out.stderr).to_string(),
            ),
            Err(e) => {
                let msg = format!("Failed to run script: {}", e);
                error!("{}", msg);
                (false, String::new(), msg)
            }
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
    let mut changed_services = vec![];

    egui::ScrollArea::vertical().show(ui, |ui| {
        ui.add_space(10.0);

        for (service, enabled) in self.services.iter() {
            let mut toggled = *enabled;
            if ui.checkbox(&mut toggled, service).changed() {
                changed_services.push((service.clone(), toggled));
            }
            ui.add_space(8.0);
        }
    });

    if !changed_services.is_empty() {
        for (service, toggled) in &changed_services {
            self.services.insert(service.clone(), *toggled);
            warn!("Toggled service '{}'. No script bound to this action.", service);
        }
        self.save_services();
        self.output = format!(
            "🔄 Toggled {} service(s): {}",
            changed_services.len(),
            changed_services
                .iter()
                .map(|(s, _)| s.clone())
                .collect::<Vec<_>>()
                .join(", ")
        );
    }
}


    fn render_optimizations_tab(&mut self, ui: &mut egui::Ui) {
        let base = Path::new("D:/Projects/w_squid/backend");

        ui.vertical(|ui| {
            ui.heading("🚀 One-Time Tweaks");
            ui.add_space(10.0);

            if ui.button("⚡ Better Power Management").clicked() {
                self.run_script_async(base.join("powerplan.ps1"), "PowerPlan".into());
                self.output = "⌛ Running PowerPlan script...".into();
            }

            if ui.button("🗑 Clean Junk Files").clicked() {
                self.run_script_async(base.join("clean_up.ps1"), "CleanUp".into());
                self.output = "⌛ Running CleanUp script...".into();
            }

            if ui.button("💿 Drive Optimization").clicked() {
                self.run_script_async(base.join("drive_optimization.ps1"), "DriveOpt".into());
                self.output = "⌛ Running Drive Optimization script...".into();
            }

            ui.add_space(20.0);
            ui.heading("🧪 Experimental Scripts");

            if ui.button("🌐 Disable IPv6").clicked() {
                self.run_script_async(base.join("disable_ipv6.ps1"), "IPv6 Disable".into());
                self.output = "⌛ Running IPv6 Disable script...".into();
            }

            if ui.button("📥 Disable Network Offloading").clicked() {
                self.run_script_async(base.join("disable_offload.ps1"), "Offload Disable".into());
                self.output = "⌛ Running Offload Disable script...".into();
            }

            if ui.button("📶 TCP Tuning Boost").clicked() {
                self.run_script_async(base.join("disable_tcp_tuning.ps1"), "TCP Tuning".into());
                self.output = "⌛ Running TCP Tuning script...".into();
            }
        });
    }
}

fn elevated_frame(elevation: u8) -> egui::Frame {
    let alpha = (elevation as f32 / 64.0).min(0.25);
    egui::Frame {
        fill: egui::Color32::from_rgb(36, 36, 36),
        stroke: egui::Stroke {
            width: (elevation as f32 / 4.0).max(1.0),
            color: egui::Color32::from_black_alpha((alpha * 255.0) as u8),
        },
        corner_radius: 6.0.into(),
        ..Default::default()
    }
}

impl eframe::App for MyApp {
    fn update(&mut self, ctx: &egui::Context, _frame: &mut eframe::Frame) {
        ctx.request_repaint_after(Duration::from_millis(100)); // periodic refresh

        egui::CentralPanel::default().show(ctx, |ui| {
            elevated_frame(12).show(ui, |ui| {
                ui.vertical_centered(|ui| {
                    ui.add_space(12.0);
                    ui.heading("⚙️ w squid");
                    ui.add_space(12.0);
                });

                ui.separator();

                elevated_frame(4).show(ui, |ui| {
                    ui.horizontal(|ui| {
                        ui.add_space(12.0);
                        if ui.selectable_label(self.active_tab == Tab::Optimizations, "🛠 Optimizations").clicked() {
                            self.active_tab = Tab::Optimizations;
                        }
                        ui.add_space(20.0);
                        if ui.selectable_label(self.active_tab == Tab::Services, "🔧 Services Toggle").clicked() {
                            self.active_tab = Tab::Services;
                        }
                        ui.add_space(12.0);
                    });
                });

                ui.add_space(12.0);
                ui.separator();

                elevated_frame(8).show(ui, |ui| {
                    ui.horizontal(|ui| {
                        ui.add_space(15.0);
                        ui.vertical(|ui| {
                            ui.add_space(15.0);
                            match self.active_tab {
                                Tab::Optimizations => self.render_optimizations_tab(ui),
                                Tab::Services => self.render_services_tab(ui),
                            }
                            ui.add_space(15.0);
                        });
                        ui.add_space(15.0);
                    });
                });

                ui.add_space(12.0);
                ui.separator();

                egui::ScrollArea::vertical()
                    .max_height(150.0)
                    .show(ui, |ui| {
                        ui.add_space(12.0);
                        ui.label(&self.output);
                        ui.add_space(12.0);
                    });

                ui.add_space(12.0);

                if let Some(rx) = &self.rx {
                    if let Ok(result) = rx.try_recv() {
                        self.output = if result.success {
                            format!("✅ {} succeeded.\n\nSTDOUT:\n{}", result.script_name, result.stdout)
                        } else {
                            format!("❌ {} failed.\n\nSTDERR:\n{}", result.script_name, result.stderr)
                        };
                        ctx.request_repaint();
                    }
                }
            });
        });
    }
}

fn main() -> Result<(), eframe::Error> {
    CombinedLogger::init(vec![TermLogger::new(
        LevelFilter::Info,
        Config::default(),
        TerminalMode::Mixed,
        ColorChoice::Auto,
    )])
    .unwrap();

    info!("Launching w_squid...");

    let options = eframe::NativeOptions::default();
    eframe::run_native("w squid", options, Box::new(|cc| Ok(Box::new(MyApp::new(&cc.egui_ctx)))))
}
