export default async (request: Request, context) => {
  const url = new URL(request.url);
  let pathname = url.pathname;

  if (url.searchParams.get('redirect') === 'false') {
    return context.next();
  }

  // Normalize consecutive slashes
  pathname = pathname.replace(/\/\/+/g, '/');

  const versionMatch = pathname.match(/^\/v\d+\.\d+/);
  if (!versionMatch) return context.next();

  const versionPath = versionMatch[0];
  const remainder = pathname.slice(versionPath.length) || '/';

  const languageCodeMatch = remainder.match(/^\/?([a-z]{2})(\/|$)/);
  let languageCode: string | null = null;
  let remainingPath = remainder;

  if (languageCodeMatch) {
    languageCode = languageCodeMatch[1];
    remainingPath = remainder.slice(languageCodeMatch[0].length);
  }

  const normalizedPath = remainingPath.replace(/^\/+/, '');

  const redirectableSections = ['about', 'blog', 'get-involved', 'news', 'search'];

  const shouldRedirect =
    normalizedPath === '' ||  // redirect to /latest/
    redirectableSections.some(section =>
      normalizedPath === section || normalizedPath.startsWith(`${section}/`)
  );

  if (shouldRedirect) {
    const newPath = `/latest/${languageCode ? `${languageCode}/` : ''}${normalizedPath}`;
    return Response.redirect(new URL(newPath, url.origin), 301);
  }

  return context.next();
};
