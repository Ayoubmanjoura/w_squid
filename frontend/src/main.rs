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

        // Dark background color
        style.visuals.window_fill = egui::Color32::from_rgba_unmultiplied(36, 36, 36, 255);

        // Custom tab selection blue color
        style.visuals.selection.bg_fill = egui::Color32::from_rgba_unmultiplied(124, 127, 235, 255);

        ctx.set_style(style);

        let mut app = Self::default();
        app.load_services();
        app
    }

    fn load_services(&mut self) {
        let path = Path::new("D:/Projects/w_squid/backend/disable/services/service.yaml");
        match fs::read_to_string(path) {
            Ok(content) => match serde_yaml::from_str::<HashMap<String, bool>>(&content) {
                Ok(map) => {
                    self.services = map;
                    self.output = "    ✅ Services loaded.".to_string();
                    info!("Services loaded successfully from {:?}", path);
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
        let path = Path::new("D:/Projects/w_squid/backend/disable/services/service.yaml");
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

    fn get_script_path(service: &str, enable: bool) -> Option<PathBuf> {
        let base = Path::new("D:/Projects/w_squid/backend");
        let sub = if enable { "enable" } else { "disable" };
        let filename = match service.to_lowercase().as_str() {
            "ipv6" => "disable_ipv6",
            "offload" => "disable_offload",
            "tcp_tuning" => "disable_tcp_tuning",
            _ => return None,
        };
        Some(base.join(sub).join(format!("{}_{}.ps1", sub, filename)))
    }

    fn run_script_async(&mut self, script_path: PathBuf, script_name: String) {
        info!("Launching script: {} -> {}", script_name, script_path.display());

        let (tx, rx) = mpsc::channel();
        self.rx = Some(rx);

        thread::spawn(move || {
            let output = Command::new("powershell")
                .args([
                    "-NoProfile",
                    "-ExecutionPolicy",
                    "Bypass",
                    "-File",
                    script_path.to_str().unwrap_or(""),
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
        egui::ScrollArea::vertical().show(ui, |ui| {
            ui.add_space(10.0);
            for (service, enabled) in self.services.clone() {
                let mut toggled = enabled;
                if ui.checkbox(&mut toggled, &service).changed() {
                    self.services.insert(service.clone(), toggled);
                    self.save_services();

                    if let Some(script_path) = Self::get_script_path(&service, toggled) {
                        let action = if toggled { "Enable" } else { "Disable" };
                        self.run_script_async(script_path, format!("{} {}", action, service));
                        self.output = format!("⌛ Running {} script...", action);
                    } else {
                        let msg = format!("⚠️ No script found for '{}'", service);
                        self.output = msg.clone();
                        warn!("{}", msg);
                    }
                }
                ui.add_space(8.0);
            }
            ui.add_space(10.0);
        });
    }

    fn render_optimizations_tab(&mut self, ui: &mut egui::Ui) {
        let base = Path::new("D:/Projects/w_squid/backend/disable");

        ui.horizontal(|ui| {
            ui.add_space(15.0); // left padding

            ui.vertical(|ui| {
                ui.add_space(10.0); // top padding

                if ui.button("⚡ Better Power Management").clicked() {
                    self.run_script_async(base.join("powerplan.ps1"), "PowerPlan".to_string());
                    self.output = "⌛ Running PowerPlan script...".to_string();
                }
                ui.add_space(10.0);

                if ui.button("🗑 Clean Junk Files").clicked() {
                    self.run_script_async(base.join("clean_up.ps1"), "CleanUp".to_string());
                    self.output = "⌛ Running CleanUp script...".to_string();
                }
                ui.add_space(10.0);

                if ui.button("💿 Drive Optimization").clicked() {
                    self.run_script_async(base.join("drive_optimization.ps1"), "DriveOpt".to_string());
                    self.output = "⌛ Running Drive Optimization script...".to_string();
                }
                ui.add_space(8.0); // bottom padding
            });

            ui.add_space(15.0); // right padding
        });
    }
}

// Fluent-inspired elevation frame with shadow & radius
fn elevated_frame(elevation: u8) -> egui::Frame {
    let alpha = (elevation as f32 / 64.0).min(0.25);
    egui::Frame {
        fill: egui::Color32::from_rgba_unmultiplied(36, 36, 36, 255),
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
        egui::CentralPanel::default().show(ctx, |ui| {
            elevated_frame(12).show(ui, |ui| {
                // Heading with padding
                ui.vertical_centered(|ui| {
                    ui.add_space(12.0);
                    ui.heading("⚙️ w squid");
                    ui.add_space(12.0);
                });

                ui.separator();

                // Tab selector with padding on all sides
                elevated_frame(4).show(ui, |ui| {
                    ui.horizontal(|ui| {
                        ui.add_space(12.0); // left padding

                        if ui
                            .selectable_label(self.active_tab == Tab::Optimizations, "🛠 Optimizations")
                            .clicked()
                        {
                            self.active_tab = Tab::Optimizations;
                        }

                        ui.add_space(20.0); // spacing between buttons

                        if ui
                            .selectable_label(self.active_tab == Tab::Services, "🔧 Services Toggle")
                            .clicked()
                        {
                            self.active_tab = Tab::Services;
                        }

                        ui.add_space(12.0); // right padding
                    });
                });

                ui.add_space(12.0);
                ui.separator();

                // Content box (Optimizations or Services) with solid padding all around
                elevated_frame(8).show(ui, |ui| {
                    ui.horizontal(|ui| {
                        ui.add_space(15.0); // left padding

                        ui.vertical(|ui| {
                            ui.add_space(15.0); // top padding

                            match self.active_tab {
                                Tab::Optimizations => self.render_optimizations_tab(ui),
                                Tab::Services => self.render_services_tab(ui),
                            }

                            ui.add_space(15.0); // bottom padding
                        });

                        ui.add_space(15.0); // right padding
                    });
                });

                ui.add_space(12.0);
                ui.separator();

                // Output box with scroll and padding
                egui::ScrollArea::vertical()
                    .max_height(150.0)
                    .show(ui, |ui| {
                        ui.add_space(12.0);
                        ui.label(&self.output);
                        ui.add_space(12.0);
                    });

                ui.add_space(12.0);

                // Handle async script results as before
                if let Some(rx) = &self.rx {
                    if let Ok(result) = rx.try_recv() {
                        if result.success {
                            self.output = format!(
                                "✅ {} succeeded.\n\nSTDOUT:\n{}",
                                result.script_name, result.stdout
                            );
                            info!("{} succeeded", result.script_name);
                        } else {
                            self.output = format!(
                                "❌ {} failed.\n\nSTDERR:\n{}",
                                result.script_name, result.stderr
                            );
                            error!("{} failed: {}", result.script_name, result.stderr);
                        }
                        ctx.request_repaint();
                    }
                }
            });
        });
    }
}

fn main() -> Result<(), eframe::Error> {
    CombinedLogger::init(vec![
        TermLogger::new(
            LevelFilter::Info,
            Config::default(),
            TerminalMode::Mixed,
            ColorChoice::Auto,
        ),
    ])
    .unwrap();

    log::info!("Launching w_squid...");

    let options = eframe::NativeOptions::default();
    eframe::run_native(
        "w squid",
        options,
        Box::new(|cc| Ok(Box::new(MyApp::new(&cc.egui_ctx)))),
    )
}

