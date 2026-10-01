// ============================================================================
//
//  Starling-Spatial-Deactivator
//  Copyright 2026 Aurelien Da Campo, All Rights Reserved.
//
//  This program is free software. You can redistribute and/or modify it
//  in accordance with the terms of the accompanying license agreement.
//
// ============================================================================

package ch.adolio.deactivator.test
{
	import ch.adolio.test.TestsResult;
	import ch.adolio.test.TestsRunner;
	import flash.desktop.NativeApplication;
	import flash.display.Sprite;

	/**
	 * Runs all the tests, then exits with code 1 if a test failed, 0 otherwise.
	 */
	public class TestMain extends Sprite
	{
		private var _testsRunner:TestsRunner = new TestsRunner();

		public function TestMain()
		{
			setupTests();

			var testsResult:TestsResult = _testsRunner.runTests();
			printResults(testsResult);

			NativeApplication.nativeApplication.exit(testsResult.failedTestsCount > 0 ? 1 : 0);
		}

		private function setupTests():void
		{
			_testsRunner.addTest(new ActivityTest());
			_testsRunner.addTest(new LifecycleTest());
			_testsRunner.addTest(new ReentrancyTest());
			_testsRunner.addTest(new CallbackTest());
			_testsRunner.addTest(new EnablingTest());
			_testsRunner.addTest(new BridgeChainTest());
		}

		private function printResults(testsResult:TestsResult):void
		{
			trace("----------------------------");
			var failedTestsCount:uint = testsResult.failedTestsCount;
			if (failedTestsCount > 0)
				trace(failedTestsCount + " / " + testsResult.results.length + " test(s) failed.");
			else
				trace("All " + testsResult.results.length + " test(s) passed.");
		}
	}
}
