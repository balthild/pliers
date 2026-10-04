import { fetchJson } from '#/utils';

declare global {
	var passkeyCreate: (name: string) => Promise<void>;
	var passkeyLogin: () => Promise<void>;
}

globalThis.passkeyCreate = async (name: string) => {
	const options = await fetchJson('/settings/passkey');
	const publicKey = PublicKeyCredential.parseCreationOptionsFromJSON(options.publicKey);

	const passkey = await navigator.credentials.create({ publicKey });

	await fetchJson('/settings/passkey', {
		method: 'POST',
		headers: { 'Content-Type': 'application/json' },
		body: JSON.stringify({ name, passkey }),
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
