enum BodyType {
  // Body types
  none,
  text,
  json,
  formData,
  stream,
  bytes,
  file,
  multipart,
  urlEncodedForm,
  xml,

  // Special body types
  raw, // Used for raw body content
}
