/*******************************************************************************
 * Copyright (c) 2010 by Thomas Jahn
 * Questions or license requests? Mail me at lithander@gmx.de!
 ******************************************************************************/
package net.pixelpracht.data.tmx 
{
	public dynamic class TmxPropertySet
	{
		public function TmxPropertySet(source:XML)
		{
			extend(source);
		}
		
		public function extend(source:XML):TmxPropertySet
		{
			for each (var prop:XML in source.property)
			{
				var key:String = prop.@name;
				var value:String = prop.@value;
				this[key] = value;
			}
			return this;
		}
	}
}