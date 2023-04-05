use bluster::{
    gatt::{
        characteristic::{self, Characteristic, Properties},
        event::{NotifySubscribe, ReadRequest},
        service::Service,
    },
    Peripheral,
};
use color_eyre::{eyre::eyre, Result};
use futures::{channel::mpsc::channel, StreamExt};
use rand::prelude::*;
use std::{collections::HashSet, time::Duration};
use tokio::task::JoinHandle;
use uuid::Uuid;

const MSG0: &str = r#"{"MAC":"Brain","User":[1001,1003],"Backend":[1102,1105],"Ble":[1202,1204],"Espnow":[1301
,1303]}"#;
const MSG1: &str = r#"{"MAC":"34:88:32:wv:ki:1m","User":[2001,2003],"Dev":[2102,2105],"Cap_errors":[{"User":[2001],"Dev":[2103]},{"User":[2001],"Dev":[2103]}]}"#;

#[tokio::main]
async fn main() -> Result<()> {
    color_eyre::install()?;
    let peripheral = Peripheral::new().await?;

    if !peripheral.is_powered().await? {
        return Err(eyre!("Bluetooth is disabled!"));
    };

    let brain_service_uuid = Uuid::parse_str("ca30c812-3ed5-44ea-961e-196a8c601de7")?;
    let error_characteristic_uuid = Uuid::parse_str("1db9a7de-135f-4509-b226-bd19d42126fd")?;

    let (sender_characteristic, receiver_characteristic) = channel(1);

    let error_characteristic = Characteristic::new(
        error_characteristic_uuid,
        Properties::new(
            Some(characteristic::Read(characteristic::Secure::Insecure(
                sender_characteristic.clone(),
            ))),
            None,
            Some(sender_characteristic),
            None,
        ),
        None,
        HashSet::new(),
    );

    let brain_service = Service::new(
        brain_service_uuid,
        true,
        HashSet::from_iter(std::iter::once(error_characteristic)),
    );

    peripheral.add_service(&brain_service)?;

    peripheral.register_gatt().await?;

    peripheral
        .start_advertising("beaker lol", &[brain_service_uuid])
        .await?;

    println!("advertising!");

    let work = tokio::spawn(async move {
        let mut rx = receiver_characteristic;

        let mut subscription: Option<JoinHandle<_>> = None;

        while let Some(event) = rx.next().await {
            match event {
                bluster::gatt::event::Event::ReadRequest(ReadRequest { response, .. }) => {
                    println!("read");
                    if response
                        .send(bluster::gatt::event::Response::Success(
                            {
                                if random() {
                                    MSG0
                                } else {
                                    MSG1
                                }
                            }
                            .as_bytes()
                            .to_vec(),
                        ))
                        .is_err()
                    {
                        eprintln!("|_ could't respond")
                    } else {
                        println!("|_ responded")
                    }
                }
                bluster::gatt::event::Event::WriteRequest(_) => println!("write"),
                bluster::gatt::event::Event::NotifySubscribe(NotifySubscribe {
                    mut notification,
                }) => {
                    println!("sub");

                    if let Some(handle) = subscription.take() {
                        handle.abort();
                    }

                    let handle = tokio::spawn(async move {
                        loop {
                            tokio::time::sleep(Duration::from_millis(800)).await;
                            if notification
                                .try_send(
                                    {
                                        if random() {
                                            MSG0
                                        } else {
                                            MSG1
                                        }
                                    }
                                    .as_bytes()
                                    .to_vec(),
                                )
                                .is_err()
                            {
                                eprintln!("couldn't notify dom")
                            };
                        }
                    });

                    subscription = Some(handle);
                }
                bluster::gatt::event::Event::NotifyUnsubscribe => {
                    println!("unsub");

                    if let Some(handle) = subscription.take() {
                        handle.abort();
                    }
                }
            }
        }
    });

    tokio::signal::ctrl_c().await?;
    println!("shutting down");

    work.abort();

    peripheral.stop_advertising().await?;
    peripheral.unregister_gatt().await?;

    Ok(())
}
