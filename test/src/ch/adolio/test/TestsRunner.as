// ============================================================================
//
//  Starling-Spatial-Deactivator
//  Copyright 2017-2026 Aurelien Da Campo, All Rights Reserved.
//
//  This program is free software. You can redistribute and/or modify it
//  in accordance with the terms of the accompanying license agreement.
//
// ============================================================================

package ch.adolio.test
{
	public class TestsRunner
	{
		private var _tests:Vector.<ITest> = new Vector.<ITest>();

		public function addTest(test:ITest):void
		{
			_tests.push(test);
		}

		public function runTests():TestsResult
		{
			var testsResult:TestsResult = new TestsResult();

			for each (var test:ITest in _tests)
			{
				try
				{
					trace("Running test: " + test);
					test.execute();
					trace("Test succeeded.");
					trace("");

					testsResult.results.push(new TestResult(test + "", true, null));
				}
				catch (error:Error)
				{
					trace("Test failed. Error: " + error.getStackTrace());
					trace("");
					testsResult.results.push(new TestResult(test + "", false, error));
				}
			}

			return testsResult;
		}
	}
}
