use enigo::{Mouse, Settings};
use gilrs::{Event, Gilrs};

fn main() -> eyre::Result<()> {
    let mut gilrs = Gilrs::new().unwrap();

    // Iterate over all connected gamepads
    for (_id, gamepad) in gilrs.gamepads() {
        println!("{} is {:?}", gamepad.name(), gamepad.power_info());
    }

    let mut engine = enigo::Enigo::new(&Settings::default())?;

    'main: loop {
        // Examine new events
        while let Some(Event { id, event, time: _ }) = gilrs.next_event_blocking(None) {
            match event {
                gilrs::EventType::ButtonPressed(button, _) => {
                    if button.is_menu() {
                        break 'main;
                    }

                    if button.is_action() {
                        engine.button(enigo::Button::Left, enigo::Direction::Press)?;
                    }
                }
                gilrs::EventType::ButtonRepeated(button, _) => {
                    println!("Repeat: {:#?} pressed", button);
                }
                gilrs::EventType::ButtonReleased(button, _) => {
                    if button.is_action() {
                        engine.button(enigo::Button::Left, enigo::Direction::Release)?;
                    }
                }
                gilrs::EventType::Connected => {
                    let pad = gilrs.gamepad(id);
                    println!(
                        "Gamepad: {} connected and is {:?}",
                        pad.name(),
                        pad.power_info()
                    );
                }
                gilrs::EventType::Disconnected => {
                    let pad = gilrs.gamepad(id);
                    println!("Gamepad: {} disconnected", pad.name());
                }
                gilrs::EventType::Dropped => todo!(),
                gilrs::EventType::ButtonChanged(_, _, _) => {}
                gilrs::EventType::AxisChanged(_, _, _) => {}
            };
        }
    }

    Ok(())
}
