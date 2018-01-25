package sqat.series2;

import sqat.series2.Dummy;

public class DependentDummy {
	Dummy x = new Dummy();
	public DependentDummy() {
		a();
	}
						
	public void a() {
		b();
	}
						
	public void b() {};
};