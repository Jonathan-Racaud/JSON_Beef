using System;
using System.Collections;

namespace JSON_Beef_Test
{
	[AlwaysInclude(AssumeInstantiated=true, IncludeAllMethods=true)]
	[Reflect]
	public class TestClass
	{
		public List<List<String>> MultipleList = new List<List<String>>();

		public ~this()
		{
			if (MultipleList != null)
			{
				for (var l in MultipleList)
				{
					DeleteContainerAndItems!(l);
				}

				delete MultipleList;
			}
		}
	}
}
