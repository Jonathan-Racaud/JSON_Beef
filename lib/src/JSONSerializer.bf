using System;
using System.Collections;
using System.Reflection;

namespace JSON_Beef
{
	public class JSONSerializer
	{
		public static Result<JSONObject> Serialize<T>(Object object) where T: JSONObject
		{
			if (object == null)
			{
				return .Err;
			}

			let json = new JSONObject();
			let type = object.GetType();
			var fields = type.GetFields();

			SerializeObjectBaseTypeInternal(object, json);

			for (var field in fields)
			{
				if (ShouldIgnore(field))
				{
					continue;
				}

				let res = SerializeObjectInternal(object, field, json);

				if (res == .Err)
				{
					return .Err;
				}
			}

			return .Ok(json);
		}

		public static Result<JSONArray> Serialize<T>(ref Object object) where T: JSONArray
		{
			if (!IsList(object) || (object == null))
			{
				return .Err;
			}

			let jsonArray = new JSONArray();
			let list = (List<Object>*)&object;

			for (var item in *list)
			{
				if (item == null)
				{
					jsonArray.Add(JSON_LITERAL.NULL);
				}
				else if (IsList(item))
				{
					let res = Serialize<JSONArray>(ref item);

					if (res == .Err)
					{
						return .Err;
					}

					jsonArray.Add(res.Get());
				}
				else
				{
					let itemType = item.GetType();

					switch (itemType)
					{
					case typeof(String):
						jsonArray.Add(item as String);
					case typeof(int):
						jsonArray.Add((int)item);
					case typeof(float):
						jsonArray.Add((float)item);
					case typeof(bool):
						jsonArray.Add(JSONUtil.BoolToLiteral((bool)item));
					default:
						let res = Serialize<JSONObject>(item);

						if (res == .Err)
						{
							return .Err;
						}

						jsonArray.Add(res.Get());
					}
				}
			}

			return .Ok(jsonArray);
		}

		private static bool IsList(Object object)
		{
			let type = object.GetType();
			let typeName = scope String();
			type.GetName(typeName);

			return typeName.Equals("List");
		}

		private static bool ShouldIgnore(FieldInfo field)
		{
			let shouldIgnore = field.GetCustomAttribute<IgnoreSerializeAttribute>();

			return ((shouldIgnore == .Ok) || field.HasFieldFlag(.PrivateScope) || field.HasFieldFlag(.Private));
		}

		private static Result<void> SerializeObjectInternal(Object object, FieldInfo field, JSONObject json)
		{
			let fieldName = scope String(field.Name);
			let fieldVariant = field.GetValue(object).Get();
			let fieldVariantType = fieldVariant.VariantType;
			var fieldValue = fieldVariant.Get<Object>();

			if (fieldValue == null)
			{
				json.Add(fieldName, JSON_LITERAL.NULL);
				return .Ok;
			}

			SerializeObjectBaseTypeInternal(fieldValue, json);

			if (IsList(fieldValue))
			{
				let res = Serialize<JSONArray>(ref fieldValue);

				if (res == .Err)
				{
					return .Err;
				}

				json.Add(fieldName, res.Get());
			}
			else
			{
				switch (fieldVariantType)
				{
				case typeof(String):
					json.Add(fieldName, (String)fieldValue);
				case typeof(int):
					json.Add(fieldName, (int)fieldValue);
				case typeof(float):
					json.Add(fieldName, (float)fieldValue);
				case typeof(bool):
					json.Add(fieldName, JSONUtil.BoolToLiteral((bool)fieldValue));
				default:
					let res = Serialize<JSONObject>(fieldValue);

					if (res == .Err)
					{
						delete json;
						return .Err;
					}

					json.Add(fieldName, res.Get());
					delete res.Get();
				}
			}

			return .Ok;
		}

		private static Result<void> SerializeObjectBaseTypeInternal(Object object, JSONObject json)
		{
			let type = object.GetType();
			let baseType = type.BaseType;

			let typeStr = scope String();
			let baseTypeStr = scope String();
			type.GetName(typeStr);
			baseType.GetName(baseTypeStr);
			

			// It is not an error to have the same base type as the current type.
			// It only tells that we arrived at the top of the inheritence chain.
			// So I exit now to break any infinite recursion loop.
			if (type == baseType)
			{
				return .Ok;
			}

			let fields = baseType.GetFields();

			for (var field in fields)
			{
				if (ShouldIgnore(field))
				{
					continue;
				}

				let fieldName = scope String(field.Name);
				let fieldVariant = field.GetValue(object).Get();
				let fieldVariantType = fieldVariant.VariantType;
				var fieldValue = fieldVariant.Get<Object>();

				SerializeObjectBaseTypeInternal(fieldValue, json);

				if (fieldValue == null)
				{
					json.Add(fieldName, JSON_LITERAL.NULL);
				}
				else if (IsList(fieldValue))
				{
					let res = Serialize<JSONArray>(ref fieldValue);

					if (res == .Err)
					{
						return .Err;
					}

					json.Add(fieldName, res.Get());
				}
				else
				{
					switch (fieldVariantType)
					{
					case typeof(String):
						json.Add(fieldName, (String)fieldValue);
					case typeof(int):
						json.Add(fieldName, (int)fieldValue);
					case typeof(float):
						json.Add(fieldName, (float)fieldValue);
					case typeof(bool):
						json.Add(fieldName, JSONUtil.BoolToLiteral((bool)fieldValue));
					default:
						let res = Serialize<JSONObject>(fieldValue);

						if (res == .Err)
						{
							delete json;
							return .Err;
						}

						json.Add(fieldName, res.Get());
						delete res.Get();
					}
				}
			}

			return .Ok;
		}

		private static Result<void> SerializeArrayInternal(Object object, FieldInfo field, JSONArray json)
		{
			let fieldVariant = field.GetValue(object).Get();
			let fieldVariantType = fieldVariant.VariantType;
			var fieldValue = fieldVariant.Get<Object>();

			if (fieldValue == null)
			{
				json.Add(JSON_LITERAL.NULL);
			}
			else if (IsList(fieldValue))
			{
				let res = Serialize<JSONArray>(ref fieldValue);

				if (res == .Err)
				{
					return .Err;
				}

				json.Add(res.Get());
			}
			else
			{
				switch (fieldVariantType)
				{
				case typeof(String):
					json.Add((String)fieldValue);
				case typeof(int):
					json.Add((int)fieldValue);
				case typeof(float):
					json.Add((float)fieldValue);
				case typeof(bool):
					json.Add(JSONUtil.BoolToLiteral((bool)fieldValue));
				default:
					let res = Serialize<JSONObject>(fieldValue);

					if (res == .Err)
					{
						delete json;
						return .Err;
					}

					json.Add(res.Get());
					delete res.Get();
				}
			}
			return .Ok;
		}
	}
}