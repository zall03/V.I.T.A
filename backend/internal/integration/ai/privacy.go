package ai

import (
	"regexp"
	"strings"
)

// Redaction is defense in depth, not complete anonymization. External use is opt-in.
func Minimize(text string, identifiers ...string) string {
	for _, id := range identifiers {
		if strings.TrimSpace(id) != "" {
			text = regexp.MustCompile(`(?i)`+regexp.QuoteMeta(id)).ReplaceAllString(text, "[REDACTED]")
		}
	}
	patterns := []string{`\b\d{16}\b`, `\b(?:\+62|62|0)\d[\d -]{7,15}\b`, `(?i)\b(?:nama|nik|alamat|telepon|nomor rekam medis|no\.? rm|ihs)\s*[:=]\s*[^\n.;]+`}
	for _, p := range patterns {
		text = regexp.MustCompile(p).ReplaceAllString(text, "[REDACTED]")
	}
	return text
}
