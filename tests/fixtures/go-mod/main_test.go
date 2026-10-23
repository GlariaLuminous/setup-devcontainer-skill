package main

import "testing"

func TestAdd(t *testing.T) {
	if got := add(1, 2); got != 3 {
		t.Fatalf("add(1, 2) = %d, want 3", got)
	}
}
