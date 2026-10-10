export interface MacroMeta {
	expanded: string;
	description: string;
}

export interface FieldMeta {
	label: string;
	min: number;
	max: number;
	unit: [singular: string, plural: string];
	period: string;
	names?: Record<string, number>;
	format?: (value: number) => string;
}

const MONTH_NAMES = [
	'January',
	'February',
	'March',
	'April',
	'May',
	'June',
	'July',
	'August',
	'September',
	'October',
	'November',
	'December',
];

const WEEKDAY_NAMES = [
	'Sunday',
	'Monday',
	'Tuesday',
	'Wednesday',
	'Thursday',
	'Friday',
	'Saturday',
];

function buildNames(names: readonly string[], offset: number): Record<string, number> {
	const map: Record<string, number> = {};
	for (const [index, name] of names.entries()) {
		const value = index + offset;
		map[name.toUpperCase()] = value;
		map[name.slice(0, 3).toUpperCase()] = value;
	}
	return map;
}

export const FIELDS: readonly FieldMeta[] = [
	{
		label: 'Minute',
		min: 0,
		max: 59,
		unit: ['minute', 'minutes'],
		period: 'hour',
	},
	{
		label: 'Hour',
		min: 0,
		max: 23,
		unit: ['hour', 'hours'],
		period: 'day',
	},
	{
		label: 'Day of Month',
		min: 1,
		max: 31,
		unit: ['day', 'days'],
		period: 'month',
	},
	{
		label: 'Month',
		min: 1,
		max: 12,
		unit: ['month', 'months'],
		period: 'year',
		names: buildNames(MONTH_NAMES, 1),
		format: (value) => MONTH_NAMES[value - 1],
	},
	{
		label: 'Day of Week',
		min: 0,
		max: 7, // 7 is accepted as an alias of 0 (Sunday)
		unit: ['day', 'days'],
		period: 'week',
		names: buildNames(WEEKDAY_NAMES, 0),
		format: (value) => WEEKDAY_NAMES[value % 7],
	},
];

export const MACROS: Record<string, MacroMeta> = {
	'@hourly': {
		expanded: '0 * * * *',
		description: 'At the start of every hour',
	},
	'@daily': {
		expanded: '0 0 * * *',
		description: 'At the start of every day (midnight)',
	},
	'@midnight': {
		expanded: '0 0 * * *',
		description: 'At the start of every day (midnight)',
	},
	'@weekly': {
		expanded: '0 0 * * 0',
		description: 'At the start of every week (midnight on Sunday)',
	},
	'@monthly': {
		expanded: '0 0 1 * *',
		description: 'At the start of every month (midnight on the 1st)',
	},
	'@yearly': {
		expanded: '0 0 1 1 *',
		description: 'At the start of every year (midnight on January 1)',
	},
	'@annually': {
		expanded: '0 0 1 1 *',
		description: 'At the start of every year (midnight on January 1)',
	},
};
