alter table public.disposal_submissions
  add column capture_latitude numeric(9, 6),
  add column capture_longitude numeric(9, 6),
  add constraint disposal_capture_coordinates_pair
    check (
      (capture_latitude is null and capture_longitude is null)
      or (capture_latitude is not null and capture_longitude is not null)
    ),
  add constraint disposal_capture_latitude_range
    check (capture_latitude is null or capture_latitude between -90 and 90),
  add constraint disposal_capture_longitude_range
    check (capture_longitude is null or capture_longitude between -180 and 180);
