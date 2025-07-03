const appId = '95IG3UJ1LV';
const apiKey = '23827432dd1f4c529eece856289a421c';
const indexName = 'istio';

const searchClient = algoliasearch(appId, apiKey);
const index = searchClient.initIndex(indexName);

function getParameterByName(name, url = window.location.href) {
    name = name.replace(/[\[\]]/g, "\\$&");
    const regex = new RegExp("[?&]" + name + "(=([^&#]*)|&|#|$)");
    const results = regex.exec(url);
    if (!results) return null;
    if (!results[2]) return '';
    return decodeURIComponent(results[2].replace(/\+/g, " "));
}

function extractVersionAndLangFromPath() {
    const pathParts = window.location.pathname.split('/');
    let version = 'latest';
    let lang = 'en';

    for (const part of pathParts) {
        if (/^v[0-9.]+$/.test(part) || part === 'latest') {
            version = part;
        } else if (/^[a-z]{2}(-[a-z]{2})?$/.test(part)) {
            lang = part;
        }
    }

    return { version, lang };
}

function updateURLParam(param, value) {
    const url = new URL(window.location.href);
    url.searchParams.set(param, value);
    window.history.pushState({}, '', url);
}

const query = getParameterByName('q') || '';
let page = parseInt(getParameterByName('page')) || 0;
const hitsPerPage = 10;

const { version, lang } = extractVersionAndLangFromPath();

// Set default dropdowns
window.addEventListener('DOMContentLoaded', () => {
    document.getElementById('version-filter').value = version;
    document.getElementById('lang-filter').value = lang;

    document.getElementById('search-query-header').innerHTML =
        `<h3>Search results for "<strong>${query}</strong>"</h3>`;

    function runSearch() {
        const selectedVersion = document.getElementById('version-filter').value;
        const selectedLang = document.getElementById('lang-filter').value;

        index.search(query, {
            hitsPerPage,
            page,
            facetFilters: [
                [`lang:${selectedLang}`],
                [`version:${selectedVersion}`]
            ]
        }).then(({ hits, nbPages }) => {
            const container = document.getElementById('search-results');
            if (hits.length === 0) {
                container.innerHTML = `<p>No results found for "<strong>${query}</strong>".</p>`;
                document.getElementById('pagination-controls').style.display = 'none';
                return;
            }

            container.innerHTML = hits.map(hit => {
                const title = hit.hierarchy?.lvl1 || '(No Title)';
                const subtitle = hit.hierarchy?.lvl2 ? ` > ${hit.hierarchy.lvl2}` : '';
                const fullUrl = hit.anchor ? `${hit.url_without_anchor}#${hit.anchor}` : hit.url;

                return `
                    <div class="search-hit">
                        <a href="${fullUrl}">
                            <h2>${title}${subtitle}</h2>
                            <p>${hit.content?.substring(0, 160) || ''}</p>
                        </a>
                        <div class="hit-meta">
                            <span><strong>URL:</strong> <a href="${fullUrl}">${fullUrl}</a></span>
                        </div>
                    </div>
                `;
            }).join('');
            document.getElementById('pagination-controls').style.display = 'flex';
            document.getElementById('page-info').textContent = `Page ${page + 1} of ${nbPages}`;
            document.getElementById('prev-page').disabled = page <= 0;
            document.getElementById('next-page').disabled = page + 1 >= nbPages;
        }).catch(err => {
            document.getElementById('search-results').innerHTML = `<p>Error fetching results: ${err.message}</p>`;
        });
    }

    document.getElementById('prev-page').addEventListener('click', () => {
        if (page > 0) {
            page--;
            updateURLParam('page', page);
            runSearch();
        }
    });

    document.getElementById('next-page').addEventListener('click', () => {
        page++;
        updateURLParam('page', page);
        runSearch();
    });

    document.getElementById('version-filter').addEventListener('change', runSearch);
    document.getElementById('lang-filter').addEventListener('change', runSearch);

    runSearch();
});
