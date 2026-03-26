package main

import (
	"errors"
	"testing"
)

// Test group 1: ParseClaudeVersion (TC-01 to TC-07)

// TC-01: Parse standard Claude Code version output
func TestParseClaudeVersion_StandardOutput(t *testing.T) {
	output := "Claude Code 2.1.69\n"
	version, err := ParseClaudeVersion(output)
	if err != nil {
		t.Errorf("expected no error, got %v", err)
	}
	if version != "2.1.69" {
		t.Errorf("expected 2.1.69, got %s", version)
	}
}

// TC-02: Parse version with v prefix and stable label
func TestParseClaudeVersion_WithVPrefix(t *testing.T) {
	output := "claude v2.1.63 stable\n"
	version, err := ParseClaudeVersion(output)
	if err != nil {
		t.Errorf("expected no error, got %v", err)
	}
	if version != "2.1.63" {
		t.Errorf("expected 2.1.63, got %s", version)
	}
}

// TC-03: Parse version with beta suffix (should extract core version only)
func TestParseClaudeVersion_WithBetaSuffix(t *testing.T) {
	output := "Claude Code 2.1.70-beta.1\n"
	version, err := ParseClaudeVersion(output)
	if err != nil {
		t.Errorf("expected no error, got %v", err)
	}
	if version != "2.1.70" {
		t.Errorf("expected 2.1.70, got %s", version)
	}
}

// TC-04: Parse unknown format (should return error)
func TestParseClaudeVersion_UnknownFormat(t *testing.T) {
	output := "unknown format\n"
	version, err := ParseClaudeVersion(output)
	if err == nil {
		t.Errorf("expected error, got nil")
	}
	if !errors.Is(err, ErrVersionParseFailure) {
		t.Errorf("expected ErrVersionParseFailure, got %v", err)
	}
	if version != "" {
		t.Errorf("expected empty string, got %s", version)
	}
}

// TC-05: Parse empty string (should return error)
func TestParseClaudeVersion_EmptyString(t *testing.T) {
	output := ""
	version, err := ParseClaudeVersion(output)
	if err == nil {
		t.Errorf("expected error, got nil")
	}
	if !errors.Is(err, ErrVersionParseFailure) {
		t.Errorf("expected ErrVersionParseFailure, got %v", err)
	}
	if version != "" {
		t.Errorf("expected empty string, got %s", version)
	}
}

// TC-06: Parse multiline output (should extract from any line)
func TestParseClaudeVersion_MultilineOutput(t *testing.T) {
	output := "Claude Code\nVersion: 2.1.69\nAuthor: Anthropic\n"
	version, err := ParseClaudeVersion(output)
	if err != nil {
		t.Errorf("expected no error, got %v", err)
	}
	if version != "2.1.69" {
		t.Errorf("expected 2.1.69, got %s", version)
	}
}

// TC-07: Parse version without trailing newline
func TestParseClaudeVersion_NoTrailingNewline(t *testing.T) {
	output := "Claude Code 2.1.69"
	version, err := ParseClaudeVersion(output)
	if err != nil {
		t.Errorf("expected no error, got %v", err)
	}
	if version != "2.1.69" {
		t.Errorf("expected 2.1.69, got %s", version)
	}
}

// Test group 2: CompareVersions (TC-08 to TC-14)

// TC-08: Compare equal versions
func TestCompareVersions_EqualVersions(t *testing.T) {
	result := CompareVersions("2.1.69", "2.1.69")
	if result != 0 {
		t.Errorf("expected 0, got %d", result)
	}
}

// TC-09: Compare lower patch version
func TestCompareVersions_LowerPatch(t *testing.T) {
	result := CompareVersions("2.1.62", "2.1.63")
	if result != -1 {
		t.Errorf("expected -1, got %d", result)
	}
}

// TC-10: Compare higher patch version
func TestCompareVersions_HigherPatch(t *testing.T) {
	result := CompareVersions("2.1.70", "2.1.69")
	if result != 1 {
		t.Errorf("expected 1, got %d", result)
	}
}

// TC-11: Compare across minor version
func TestCompareVersions_CrossMinor(t *testing.T) {
	result := CompareVersions("2.1.69", "2.2.0")
	if result != -1 {
		t.Errorf("expected -1, got %d", result)
	}
}

// TC-12: Compare across major version
func TestCompareVersions_CrossMajor(t *testing.T) {
	result := CompareVersions("2.1.69", "3.0.0")
	if result != -1 {
		t.Errorf("expected -1, got %d", result)
	}
}

// TC-13: Compare at HTTP hooks threshold boundary
func TestCompareVersions_HTTPHooksThreshold(t *testing.T) {
	result := CompareVersions("2.1.63", MinVersionHTTPHooks)
	if result != 0 {
		t.Errorf("expected 0, got %d", result)
	}
}

// TC-14: Compare at full features threshold boundary
func TestCompareVersions_FullFeaturesThreshold(t *testing.T) {
	result := CompareVersions("2.1.69", MinVersionFullFeatures)
	if result != 0 {
		t.Errorf("expected 0, got %d", result)
	}
}
