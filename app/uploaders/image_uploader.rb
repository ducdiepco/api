class ImageUploader < CarrierWave::Uploader::Base

  include CarrierWave::MiniMagick

  storage :file

  def store_dir
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

  version :small do
    process :resize_to_limit => [400, 200]
    process :quality => 60
  end

  def extension_white_list
    %w(jpg jpeg png)
  end
end