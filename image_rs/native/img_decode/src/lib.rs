use std::result::Result;
use image;
use std::vec::Vec;
use image::{ColorType, GenericImageView};
use rustler::types::binary::{Binary};

type ElixirImageResultTuple = (Vec<u8>, (u32, u32, u32), &'static str, &'static str);

fn _get_image(img: &image::DynamicImage) -> ElixirImageResultTuple {
    let (channels, color, pix_fmt) = match img.color() {
        ColorType::L8 => (1, "l", "u8"),
        ColorType::La8 => (2, "la", "u8"),
        ColorType::Rgb8 => (3, "rgb", "u8"),
        ColorType::Rgba8 => (4, "rgba", "u8"),
        ColorType::L16 => (1, "l", "u16"),
        ColorType::La16 => (2, "la", "u16"),
        ColorType::Rgb16 => (3, "rgb", "u16"),
        ColorType::Rgba16 => (4, "rgba", "u16"),
        ColorType::Bgr8 => (3, "bgr", "u8"),
        ColorType::Bgra8 => (4, "bgra", "u8"),
        _ => (0, "unknown", "unknown")
    };
    let width = img.width();
    let height = img.height();
    let b = img.to_bytes();
    (b, (height, width, channels), pix_fmt, color)
}

#[rustler::nif]
fn from_file(filename: &str) -> Result<ElixirImageResultTuple, &'static str> {
    if let Ok(img) = image::open(filename) {
        Ok(_get_image(&img))
    } else {
        Err("cannot decode image")
    }
}

#[rustler::nif]
fn from_memory(buffer: Binary) -> Result<ElixirImageResultTuple, &'static str> {
    if let Ok(img) = image::load_from_memory(buffer.as_slice()) {
        Ok(_get_image(&img))
    } else {
        Err("cannot decode image")
    }
}

rustler::init!("Elixir.ImgDecode.Nif", [from_file, from_memory]);
