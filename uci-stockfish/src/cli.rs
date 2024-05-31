use clap::{Parser};

const AUTHOR: &str = "
Author : Fabrice Corraire <antidote1911@gmail.com>
Github : https://github.com/Antidote1911/
";

#[derive(Parser)]
#[clap(about, author=AUTHOR, version)]
pub struct Cli {
    /// The path to the executable
    #[clap(short, long)]
    executablepath: String,

    /// Number of core to use
    #[clap(short, long)]
    port: u16,
}

impl Cli {
    pub fn executablepath(&self) -> String {
        self.executablepath.to_string()
    }
    pub fn port(&self) -> u16 {
        self.port
    }
}