globalThis.$ = (selector) => {
	const element = document.querySelector(selector);
	if (!element) throw new Error(`Element not found: ${selector}`);

	return Alpine.$data(element);
};

globalThis.fetchJson = async (url, options = {}) => {
	options.headers ??= {};
	options.headers['Accept'] ??= 'application/json';

	const response = await fetch(url, options);

	if (!response.ok) {
		const data = await response.json();
		throw new Error(data.reason ?? response.statusText);
	}

	if (response.status === 204) {
		return undefined;
	}

	return await response.json();
};

globalThis.passkeyCreate = async () => {
	const options = await fetchJson('/settings/passkey');
	const publicKey = PublicKeyCredential.parseCreationOptionsFromJSON(options.publicKey);

	const passkey = await navigator.credentials.create({ publicKey });

	await fetchJson('/settings/passkey', {
		method: 'POST',
		headers: { 'Content-Type': 'application/json' },
		body: JSON.stringify({ name: this.name, passkey }),
	});

	location.reload();
};

globalThis.passkeyLogin = async () => {
	const options = await fetchJson('/login/passkey');
	const publicKey = PublicKeyCredential.parseRequestOptionsFromJSON(options.publicKey);

	const passkey = await navigator.credentials.get({ publicKey });

	await fetchJson('/login/passkey', {
		method: 'POST',
		headers: { 'Content-Type': 'application/json' },
		body: JSON.stringify({ passkey }),
	});

	location.assign('/');
};
