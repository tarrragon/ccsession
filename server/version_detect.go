package main

import (
	"regexp"
	"strconv"
	"strings"
)

// ParseClaudeVersion extracts the semantic version from claude --version output.
// It uses VersionPattern to find the first MAJOR.MINOR.PATCH version string.
//
// Examples:
//   - "Claude Code 2.1.69\n" → ("2.1.69", nil)
//   - "claude v2.1.63 stable\n" → ("2.1.63", nil)
//   - "Claude Code 2.1.70-beta.1\n" → ("2.1.70", nil)
//   - "unknown format\n" → ("", ErrVersionParseFailure)
func ParseClaudeVersion(output string) (string, error) {
	re := regexp.MustCompile(VersionPattern)
	matches := re.FindStringSubmatch(output)
	if len(matches) < 2 {
		return "", ErrVersionParseFailure
	}
	return matches[1], nil
}

// CompareVersions compares two semantic version strings.
// Returns: -1 if a < b, 0 if a == b, 1 if a > b.
// Format errors result in safe degradation (returns 0).
func CompareVersions(a, b string) int {
	aParts := parseVersionComponents(a)
	bParts := parseVersionComponents(b)

	// Safe degradation: if either version is unparseable, return equal
	if aParts == nil || bParts == nil {
		return 0
	}

	// Compare major, minor, patch in order
	for i := 0; i < 3; i++ {
		if aParts[i] < bParts[i] {
			return -1
		}
		if aParts[i] > bParts[i] {
			return 1
		}
	}

	return 0
}

// parseVersionComponents parses a version string into [major, minor, patch] integers.
// Returns nil if the version string is malformed.
func parseVersionComponents(version string) *[3]int {
	parts := strings.Split(strings.TrimSpace(version), ".")
	if len(parts) < 3 {
		return nil
	}

	result := &[3]int{}
	for i := 0; i < 3; i++ {
		// Extract only the numeric part from the segment (e.g., "70-beta.1" → "70")
		segment := parts[i]
		for j := 0; j < len(segment); j++ {
			if segment[j] < '0' || segment[j] > '9' {
				segment = segment[:j]
				break
			}
		}

		num, err := strconv.Atoi(segment)
		if err != nil || segment == "" {
			return nil
		}
		result[i] = num
	}

	return result
}
