--!strict
-- Tipe data untuk sistem dialog NPC. Hanya berisi type, tidak ada logika.

export type Line = {
	text: string, -- boleh memakai placeholder {NamaKey} yang diambil dari GameConfig
	speaker: string?, -- default: displayName NPC
}

export type Conversation = {
	lines: { Line },
	-- Flag dialog yang di-set server setelah percakapan selesai atau dilewati.
	setFlags: { [string]: any }?,
	-- Dipanggil server setelah percakapan selesai/dilewati (sesi sudah divalidasi).
	-- Dipakai mis. untuk menerima quest atau menyerahkan hasil quest.
	onFinish: ((ctx: SelectContext) -> ())?,
}

export type SelectContext = {
	player: Player,
	hasFlag: (key: string) -> boolean,
	getFlag: (key: string) -> any,
}

export type PromptSettings = {
	actionText: string?,
	maxActivationDistance: number?,
}

export type NPCDefinition = {
	id: string,
	displayName: string,
	-- Nama Model NPC yang SUDAH ADA di Workspace (dicari rekursif, tidak dibuat/diubah).
	modelName: string,
	-- Nama part di dalam model yang jadi titik fokus kamera saat dialog (default "Head").
	focusPartName: string?,
	prompt: PromptSettings?,
	conversations: { [string]: Conversation },
	-- Mengembalikan key di `conversations` yang harus dimainkan untuk pemain ini.
	selectConversation: (ctx: SelectContext) -> string,
}

return {}
