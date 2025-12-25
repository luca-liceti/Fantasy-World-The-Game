#!/usr/bin/env -S godot --headless --script
## Quick test runner for combat system tests
## Run with: godot --headless --script tests/run_combat_tests.gd --quit
extends SceneTree

func _init() -> void:
	print("\n╔══════════════════════════════════════════════╗")
	print("║   ENHANCED COMBAT SYSTEM - TEST RUNNER       ║")
	print("╚══════════════════════════════════════════════╝\n")
	
	# Create test instance
	var test_instance = CombatSystemTests.new()
	root.add_child(test_instance)
	
	# Run all test suites
	var unit_results = test_instance.run_all_tests()
	var integration_results = test_instance.run_integration_tests()
	var extended_results = test_instance.run_extended_tests()
	
	# Calculate totals
	var total_passed = unit_results["passed"] + integration_results["passed"] + extended_results["passed"]
	var total_failed = unit_results["failed"] + integration_results["failed"] + extended_results["failed"]
	var total_tests = total_passed + total_failed
	
	# Print summary
	print("\n╔══════════════════════════════════════════════╗")
	print("║              FINAL TEST SUMMARY              ║")
	print("╠══════════════════════════════════════════════╣")
	print("║  Unit Tests:        %3d passed / %3d total   ║" % [unit_results["passed"], unit_results["total"]])
	print("║  Integration Tests: %3d passed / %3d total   ║" % [integration_results["passed"], integration_results["total"]])
	print("║  Extended Tests:    %3d passed / %3d total   ║" % [extended_results["passed"], extended_results["total"]])
	print("╠══════════════════════════════════════════════╣")
	print("║  TOTAL:             %3d passed / %3d total   ║" % [total_passed, total_tests])
	if total_failed == 0:
		print("║                                              ║")
		print("║           ✓ ALL TESTS PASSED! ✓             ║")
	else:
		print("║                                              ║")
		print("║           ✗ %3d TESTS FAILED ✗               ║" % total_failed)
	print("╚══════════════════════════════════════════════╝\n")
	
	# Exit with error code if any tests failed
	if total_failed > 0:
		quit(1)
	else:
		quit(0)
