--!strict

export type IndexObject      = { Index: number, Last: Instance? };

export type Settings         = { [string]: (string | number | boolean | { [number]: string })};

export type AnyScript        = (Script | ModuleScript | LocalScript);


export type PropertiesObject = {
	[string?]        : any,
	
	__Attributes__   : { [string?]: {
		Type: string,
		Value: any
	}},
	__Tags__         : { [number?]: string } 
};
export type DataObject       = {
	__Properties__: PropertiesObject, 
	__Source__    : string?,
};
export type ParentDataObject = DataObject & {
	[string]: ParentDataObject?
};
export type DataRoot         = {
	[string]: ParentDataObject?
};



return nil :: nil;