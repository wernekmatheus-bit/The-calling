
export type LanguageCode = 'en' | 'pt' | 'es' | 'fr' | 'it' | 'de';

export interface LocalizedString {
  [key: string]: string; // e.g. "en": "Value", "pt": "Valor"
}

export interface BibleState {
  topic_id: string; // 'finance', 'love', etc.
  book_name: string; // 'Proverbs'
  current_chapter: number;
  total_chapters: number;
  completed_chapters: number[]; // Array of chapter numbers
  last_read_at: string;
}

export interface Profile {
  id: string;
  xp: number;
  level: number;
  current_streak: number;
  last_access: string;
  preferred_language: LanguageCode;
  bible_state?: BibleState; // JSONB column
}

export interface Course {
  id: string;
  title: LocalizedString;
  description: LocalizedString;
  next_course_id?: string;
  is_locked: boolean;
}

export interface WhitelistCustomer {
  email: string;
  products_owned: string[];
}
