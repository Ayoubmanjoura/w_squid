use eframe::egui;
use std::fs::{self, OpenOptions};
use std::io::Write;
use std::path::{Path, PathBuf};
use std::process::Command;
use chrono::Local;

fn main() -> Result<(), eframe::Error> {
    let options = eframe::NativeOptions::default();
    eframe::run_native("W Squid", options, Box::new(|_cc| Box::new(MyApp::default())))
}

#[derive(Default)]
struct MyApp {
    output: String,
}

impl eframe::App for MyApp {
    fn update(&mut self, ctx: &egui::Context, _frame: &mut eframe::Frame) {
        egui::CentralPanel::default().show(ctx, |ui| {
            ui.heading("🦑 W Squid");

            if ui.button("⚡ Better Power Management").clicked() {
                self.output = run_script("backend\\powerplan.ps1", "PowerPlan");
            }

            if ui.button("🗑 Clean Junk Files").clicked() {
                self.output = run_script("backend\\clean_up.ps1", "CleanUp");
            }

            if ui.button("💿 Drive Optimization").clicked() {
                self.output = run_script("backend\\drive_optimization.ps1", "DriveOpt");
            }

            ui.separator();
            ui.label(&self.output);
        });
    }
}

fn run_script(script_path: &str, script_name: &str) -> String {
    let output = Command::new("powershell")
        .args([
            "-NoProfile",
            "-ExecutionPolicy", "Bypass",
            "-File", script_path,
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

            let log = format!(
                "[{}] [{}] {}\nSTDOUT:\n{}\nSTDERR:\n{}\n---\n",
                Local::now().format("%Y-%m-%d %H:%M:%S"),
                script_name,
                status,
                stdout,
                stderr
            );

            write_log(&log);

            if output.status.success() {
                format!("✅ {} executed successfully.\n\nSTDOUT:\n{}", script_name, stdout)
            } else {
                format!("❌ {} failed.\n\nSTDERR:\n{}", script_name, stderr)
            }
        }
        Err(e) => {
            let log = format!(
                "[{}] [{}] ❌ Error running script: {}\n---\n",
                Local::now().format("%Y-%m-%d %H:%M:%S"),
                script_name,
                e
            );
            write_log(&log);
            format!("❌ Failed to run script: {}", e)
        }
    }
}

fn write_log(content: &str) {
    let log_dir = dirs::data_dir()
        .unwrap_or_else(|| PathBuf::from("logs_fallback"))
        .join("W-Squid")
        .join("logs");

    if !log_dir.exists() {
        if let Err(e) = fs::create_dir_all(&log_dir) {
            eprintln!("Couldn't create log dir: {}", e);
            return;
        }
    }

    let log_file = log_dir.join("w_squid.log");

    let mut file = match OpenOptions::new().create(true).append(true).open(&log_file) {
        Ok(f) => f,
        Err(e) => {
            eprintln!("Couldn't open log file: {}", e);
            return;
        }
    };

    if let Err(e) = writeln!(file, "{}", content) {
        eprintln!("Couldn't write to log file: {}", e);
    }
}
// This code is a simple GUI application using eframe and egui to run PowerShell scripts for system maintenance tasks.
// It includes buttons for better power management, cleaning junk files, and drive optimization.