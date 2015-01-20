import utest.*;
import utest.ui.Report;
import tests.*;

class TestAll
{
	public static function main()
	{
		var runner = new Runner();

		runner.addCase(new TestDefs());
		runner.addCase(new TestDecoder());
		runner.addCase(new TestDispatch());
		Report.create(runner);

		var r:TestResult = null;
		runner.onProgress.add(function(o) if (o.done == o.totals) r = o.result);
		runner.run();

#if sys
		if (r.allOk())
			Sys.exit(0);
		else
			Sys.exit(1);
#end

	}
}
