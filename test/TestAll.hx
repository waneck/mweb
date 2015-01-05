import utest.*;
import utest.ui.Report;

class TestAll
{
	public static function main()
	{
		var runner = new Runner();

		// runner.addCase(new McliTests());
		var r = mweb.Route.route({ a: 1, b: 2 });
		trace(r);
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
