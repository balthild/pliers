import { FIELDS, MACROS } from './meta';
import type { FieldMeta } from './meta';
import { parseTerm } from './parse';
import type { Term } from './parse';

export interface CronExplanation {
	macro: CronMacroExplanation | null;
	fields: CronFieldExplanation[];
}

export interface CronMacroExplanation {
	value: string;
	expanded: string;
	description: string;
}

export interface CronFieldExplanation {
	label: string;
	value: string;
	description: string | null;
}

export function explainCronExpr(expr: string): CronExplanation | null {
	const trimmed = expr.trim();
	if (trimmed === '') return null;

	const macro = explainCronMacro(trimmed);
	const parts = (macro?.expanded ?? trimmed).split(/\s+/);
	if (parts.length !== FIELDS.length) return null;

	return {
		macro,
		fields: FIELDS.map((meta, index) => {
			const raw = parts[index];
			return {
				label: meta.label,
				value: raw,
				description: explainCronField(raw, meta),
			};
		}),
	};
}

export function explainCronMacro(raw: string): CronMacroExplanation | null {
	const value = raw.trim().toLowerCase();
	const meta = MACROS[value];
	if (meta === undefined) return null;

	return {
		value,
		expanded: meta.expanded,
		description: meta.description,
	};
}

function explainCronField(raw: string, meta: FieldMeta): string | null {
	const tokens = raw.split(',').map((token) => token.trim());

	const terms: Term[] = [];
	for (const token of tokens) {
		const term = parseTerm(token, meta);
		if (term === null) return null;
		terms.push(term);
	}

	// a bare wildcard matches everything.
	if (tokens.includes('*')) {
		return `Every ${meta.unit[0]} of every ${meta.period}`;
	}

	// a single specific value
	if (terms.length === 1 && terms[0].start === terms[0].end) {
		const value = formatValue(terms[0].start, meta);
		const subject = meta.names ? value : `${meta.unit[0]} ${value}`;
		return `${capitalize(subject)} of every ${meta.period}`;
	}

	// a list of specific values
	if (terms.every((term) => term.start === term.end)) {
		const values = terms.map((term) => formatValue(term.start, meta));
		const subject = meta.names ? listText(values) : `${meta.unit[1]} ${listText(values)}`;
		return `${capitalize(subject)} of every ${meta.period}`;
	}

	// complex terms
	const descriptions = terms.map((term) => describeTerm(term, meta));
	return `${capitalize(listText(descriptions))} of every ${meta.period}`;
}

function describeTerm(term: Term, meta: FieldMeta): string {
	const [singular, plural] = meta.unit;
	const start = formatValue(term.start, meta);

	if (term.start === term.end) {
		return meta.names ? start : `${singular} ${start}`;
	}

	if (term.step > 1) {
		const base = `every ${term.step} ${plural}`;
		if (term.end === meta.max) {
			return term.start === meta.min ? base : `${base} starting at ${start}`;
		}
		return `${base} from ${start} through ${formatValue(term.end, meta)}`;
	}

	return meta.names
		? `${start} through ${formatValue(term.end, meta)}`
		: `${plural} ${start} through ${formatValue(term.end, meta)}`;
}

function formatValue(value: number, meta: FieldMeta): string {
	return meta.format ? meta.format(value) : String(value);
}

function listText(items: string[]): string {
	if (items.length <= 1) return items.join('');
	if (items.length === 2) return `${items[0]} and ${items[1]}`;
	return `${items.slice(0, -1).join(', ')} and ${items[items.length - 1]}`;
}

function capitalize(text: string): string {
	return text.charAt(0).toUpperCase() + text.slice(1);
}
