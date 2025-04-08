export default async (request: Request) => {
  const url = new URL(request.url);
  // Match paths that start with "/v" followed by a version number
  const versionMatch = url.pathname.match(/^\/v\d+(\.\d+)*/);
  if (versionMatch) {
    // Get the rest of the path after the version
    const remainder = url.pathname.slice(versionMatch[0].length);
    // These are the allowed subpaths under /latest/
    const allowedSections = ['/', '/about', '/blog', '/get-involved', '/news', '/search'];
    // Check if the remainder matches any of the allowed sections
    const matchesSection = allowedSections.some(section =>
      remainder === section || remainder.startsWith(section + '/')
    );
    if (matchesSection) {
      const newPath = '/latest' + remainder;
      return Response.redirect(new URL(newPath, url.origin), 301);
    }
  }
  return fetch(request);
};