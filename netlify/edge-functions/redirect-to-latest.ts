export default async (request: Request) => {
  const url = new URL(request.url);
  
  // Match paths starting with "/v" followed by a version number pattern
  // Excludes paths containing "/docs/"
  if (url.pathname.match(/^\/v\d+(\.\d+)*/) && !url.pathname.includes('/docs/')) {
    // Preserve the rest of the path after the version part
    const newPath = url.pathname.replace(/^\/v\d+(\.\d+)*/, '/latest');
    
    return Response.redirect(new URL(newPath, url.origin), 301);
  }
  
  return fetch(request);
};