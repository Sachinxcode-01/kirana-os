/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: false,
  images: {
    unoptimized: true,
  },
  // Ensure trailing slashes do not break API or page routing
  trailingSlash: false,
};

export default nextConfig;
