"use client";

import { useEffect, useState } from "react";

import { disposalPhotoPlaceholderPath } from "@/features/admin-disposals/constants";

interface DisposalPhotoProps {
  photoUrl?: string | null;
  alt?: string;
  className?: string;
}

export const DisposalPhoto = ({
  photoUrl,
  alt = "Foto do descarte",
  className = "h-44 w-full object-cover"
}: DisposalPhotoProps) => {
  const [src, setSrc] = useState(photoUrl ?? disposalPhotoPlaceholderPath);

  useEffect(() => {
    setSrc(photoUrl ?? disposalPhotoPlaceholderPath);
  }, [photoUrl]);

  return (
    // eslint-disable-next-line @next/next/no-img-element
    <img
      src={src}
      alt={alt}
      className={className}
      onError={() => {
        if (src !== disposalPhotoPlaceholderPath) {
          setSrc(disposalPhotoPlaceholderPath);
        }
      }}
    />
  );
};
