use slint::{ComponentHandle, SharedString};
use std::{collections::HashMap, fs, path::Path, process::Command, sync::{Arc, Mutex}, thread};

slint::include_modules!("./ui/main.slint");

#[derive(Default)]
struct AppState {
    services: HashMap<String, bool>,
    output: String,
}

fn main() {
    let app = MainWindow::new().unwrap();
    let state = Arc::new(Mutex::new(AppState::default()));

    let state_clone = state.clone();
    let app_clone = app.clone();
    app.on_run_script(move |script_name| {
        let name = script_name.to_string();
        let state = state_clone.clone();
        let app = app_clone.clone();

        thread::spawn(move || {
            let script_path = format!("D:/Projects/w_squid/backend/{}.ps1", name);
            let output = Command::new("powershell")
                .args(["-NoProfile", "-ExecutionPolicy", "Bypass", "-File", &script_path])
                .output();

            let result = match output {
                Ok(out) => {
                    if out.status.success() {
                        format!("✅ {} succeeded.\n{}", name, String::from_utf8_lossy(&out.stdout))
                    } else {
                        format!("❌ {} failed.\n{}", name, String::from_utf8_lossy(&out.stderr))
                    }
                }
                Err(e) => format!("❌ Failed to run {}: {}", name, e),
            };

            state.lock().unwrap().output = result.clone();
            app.set_output_text(SharedString::from(result));
        });
    });

    let app_state = state.clone();
    let app_clone = app.clone();
    app.on_toggle_service(move |name, enabled| {
        let mut s = app_state.lock().unwrap();
        s.services.insert(name.to_string(), enabled);

        // Save to YAML
        let _ = fs::write(
            "D:/Projects/w_squid/backend/services/service.yaml",
            serde_yaml::to_string(&s.services).unwrap(),
        );

        let msg = format!("🔄 Toggled service: {} = {}", name, enabled);
        s.output = msg.clone();
        app_clone.set_output_text(SharedString::from(msg));
    });

    // Load initial services
    let mut s = state.lock().unwrap();
    let content = fs::read_to_string("D:/Projects/w_squid/backend/services/service.yaml").unwrap_or_default();
    s.services = serde_yaml::from_str(&content).unwrap_or_default();
    drop(s); // release lock

    // TODO: Bind services to Slint dynamically if needed

    app.run().unwrap();
}
