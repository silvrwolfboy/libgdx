// Do not edit this file! Generated by Ragel.
// Ragel.exe -G2 -J -o JsonReader.java JsonReader.rl
/*******************************************************************************
 * Copyright 2011 See AUTHORS file.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 ******************************************************************************/

package com.badlogic.gdx.utils;

import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.Reader;

import com.badlogic.gdx.files.FileHandle;
import com.badlogic.gdx.utils.JsonValue.ValueType;

/** Lightweight JSON parser.<br>
 * <br>
 * The default behavior is to parse the JSON into a DOM containing {@link JsonValue} objects. Extend this class and override
 * methods to perform event driven parsing. When this is done, the parse methods will return null.
 * @author Nathan Sweet */
public class JsonReader implements BaseJsonReader {
	public JsonValue parse (String json) {
		char[] data = json.toCharArray();
		return parse(data, 0, data.length);
	}

	public JsonValue parse (Reader reader) {
		try {
			char[] data = new char[1024];
			int offset = 0;
			while (true) {
				int length = reader.read(data, offset, data.length - offset);
				if (length == -1) break;
				if (length == 0) {
					char[] newData = new char[data.length * 2];
					System.arraycopy(data, 0, newData, 0, data.length);
					data = newData;
				} else
					offset += length;
			}
			return parse(data, 0, offset);
		} catch (IOException ex) {
			throw new SerializationException(ex);
		} finally {
			StreamUtils.closeQuietly(reader);
		}
	}

	public JsonValue parse (InputStream input) {
		try {
			return parse(new InputStreamReader(input, "UTF-8"));
		} catch (IOException ex) {
			throw new SerializationException(ex);
		} finally {
			StreamUtils.closeQuietly(input);
		}
	}

	public JsonValue parse (FileHandle file) {
		try {
			return parse(file.reader("UTF-8"));
		} catch (Exception ex) {
			throw new SerializationException("Error parsing file: " + file, ex);
		}
	}

	public JsonValue parse (char[] data, int offset, int length) {
		int cs, p = offset, pe = length, eof = pe, top = 0;
		int[] stack = new int[4];

		int s = 0;
		Array<String> names = new Array(8);
		boolean needsUnescape = false, stringIsName = false, stringIsUnquoted = false;
		RuntimeException parseRuntimeEx = null;

		boolean debug = false;
		if (debug) System.out.println();

		try {
		%%{
			machine json;

			prepush {
				if (top == stack.length) {
					int[] newStack = new int[stack.length * 2];
					System.arraycopy(stack, 0, newStack, 0, stack.length);
					stack = newStack;
				}
			}

			action buffer {
				s = p;
				needsUnescape = false;
			}
			action name {
				stringIsName = true;
			}
			action string {
				String value = new String(data, s, p - s);
				s = p;
				if (needsUnescape) value = unescape(value);
				outer:
				if (stringIsName) {
					stringIsName = false;
					if (debug) System.out.println("name: " + value);
					names.add(value);
				} else {
					String name = names.size > 0 ? names.pop() : null;
					if (stringIsUnquoted) {
						if (value.equals("true")) {
							if (debug) System.out.println("boolean: " + name + "=true");
							bool(name, true);
							break outer;
						} else if (value.equals("false")) {
							if (debug) System.out.println("boolean: " + name + "=false");
							bool(name, false);
							break outer;
						} else if (value.equals("null")) {
							string(name, null);
							break outer;
						} else if (value.indexOf('.') != -1) {
							try {
								if (debug) System.out.println("double: " + name + "=" + Double.parseDouble(value));
								number(name, Double.parseDouble(value));
								break outer;
							} catch (NumberFormatException ignored) {}
						} else {
							try {
								if (debug) System.out.println("double: " + name + "=" + Double.parseDouble(value));
								number(name, Long.parseLong(value));
								break outer;
							} catch (NumberFormatException ignored) {}
						}
					}
					if (debug) System.out.println("string: " + name + "=" + value);
					string(name, value);
				}
				stringIsUnquoted = false;
			}
			action startObject {
				String name = names.size > 0 ? names.pop() : null;
				if (debug) System.out.println("startObject: " + name);
				startObject(name);
				fcall object;
			}
			action endObject {
				if (debug) System.out.println("endObject");
				pop();
				fret;
			}
			action startArray {
				String name = names.size > 0 ? names.pop() : null;
				if (debug) System.out.println("startArray: " + name);
				startArray(name);
				fcall array;
			}
			action endArray {
				if (debug) System.out.println("endArray");
				pop();
				fret;
			}
			action comment {
				if (debug) System.out.println("comment /" + data[p]);
				if (data[p++] == '/') {
					while (data[p] != '\n')
						p++;
				} else {
					while (data[p] != '*' || data[p + 1] != '/')
						p++;
					p++;
				}
			}
			action unquotedChars {
				if (debug) System.out.println("unquotedChars");
				s = p;
				needsUnescape = false;
				stringIsUnquoted = true;
				if (stringIsName) {
					outer:
					while (true) {
						switch (data[p]) {
						case ':':
						case ' ':
						case '\r':
						case '\n':
						case '\t':
							break outer;
						}
						// if (debug) System.out.println("unquotedChar (name): '" + data[p] + "'");
						p++;
					}
				} else {
					outer:
					while (true) {
						switch (data[p]) {
						case '}':
						case ']':
						case ',':
						case ' ':
						case '\r':
						case '\n':
						case '\t':
							break outer;
						}
						// if (debug) System.out.println("unquotedChar (value): '" + data[p] + "'");
						p++;
					}
				}
				p--;
			}
			action quotedChars {
				if (debug) System.out.println("quotedChars");
				s = ++p;
				needsUnescape = false;
				outer:
				while (true) {
					switch (data[p]) {
					case '\\':
						needsUnescape = true;
						p++;
						break;
					case '"':
						break outer;
					}
					// if (debug) System.out.println("quotedChar: '" + data[p] + "'");
					p++;
				}
				p--;
			}

			ws = [ \r\n\t] | (('//' | '/*') @comment);
			string = '"' @quotedChars %string '"' | ^[{}\[\],:"\r\n\t ] >unquotedChars %string;
			value = '{' @startObject | '[' @startArray | string;
			nameValue = string >name ws* ':' ws* value;
			object := ws* nameValue? ws* (',' ws* nameValue ws*)** ','? ws* '}' @endObject;
			array := ws* value? ws* (',' ws* value ws*)** ','? ws* ']' @endArray;
			main := ws* value ws*;

			write init;
			write exec;
		}%%
		} catch (RuntimeException ex) {
			parseRuntimeEx = ex;
		}

		JsonValue root = this.root;
		this.root = null;
		current = null;
		lastChild.clear();

		if (p < pe) {
			int lineNumber = 1;
			for (int i = 0; i < p; i++)
				if (data[i] == '\n') lineNumber++;
			throw new SerializationException("Error parsing JSON on line " + lineNumber + " near: " + new String(data, p, pe - p),
				parseRuntimeEx);
		} else if (elements.size != 0) {
			JsonValue element = elements.peek();
			elements.clear();
			if (element != null && element.isObject())
				throw new SerializationException("Error parsing JSON, unmatched brace.");
			else
				throw new SerializationException("Error parsing JSON, unmatched bracket.");
		} else if (parseRuntimeEx != null) {
			throw new SerializationException("Error parsing JSON: " + new String(data), parseRuntimeEx);
		}
		return root;
	}

	%% write data;

	private final Array<JsonValue> elements = new Array(8);
	private final Array<JsonValue> lastChild = new Array(8);
	private JsonValue root, current;

	private void addChild (String name, JsonValue child) {
		child.setName(name);
		if (current == null) {
			current = child;
			root = child;
		} else if (current.isArray() || current.isObject()) {
			if (current.size == 0)
				current.child = child;
			else {
				JsonValue last = lastChild.pop();
				last.next = child;
				child.prev = last;
			}
			lastChild.add(child);
			current.size++;
		} else
			root = current;
	}

	protected void startObject (String name) {
		JsonValue value = new JsonValue(ValueType.object);
		if (current != null) addChild(name, value);
		elements.add(value);
		current = value;
	}

	protected void startArray (String name) {
		JsonValue value = new JsonValue(ValueType.array);
		if (current != null) addChild(name, value);
		elements.add(value);
		current = value;
	}

	protected void pop () {
		root = elements.pop();
		if (current.size > 0) lastChild.pop();
		current = elements.size > 0 ? elements.peek() : null;
	}

	protected void string (String name, String value) {
		addChild(name, new JsonValue(value));
	}

	protected void number (String name, double value) {
		addChild(name, new JsonValue(value));
	}

	protected void number (String name, long value) {
		addChild(name, new JsonValue(value));
	}

	protected void bool (String name, boolean value) {
		addChild(name, new JsonValue(value));
	}

	private String unescape (String value) {
		int length = value.length();
		StringBuilder buffer = new StringBuilder(length + 16);
		for (int i = 0; i < length;) {
			char c = value.charAt(i++);
			if (c != '\\') {
				buffer.append(c);
				continue;
			}
			if (i == length) break;
			c = value.charAt(i++);
			if (c == 'u') {
				buffer.append(Character.toChars(Integer.parseInt(value.substring(i, i + 4), 16)));
				i += 4;
				continue;
			}
			switch (c) {
			case '"':
			case '\\':
			case '/':
				break;
			case 'b':
				c = '\b';
				break;
			case 'f':
				c = '\f';
				break;
			case 'n':
				c = '\n';
				break;
			case 'r':
				c = '\r';
				break;
			case 't':
				c = '\t';
				break;
			default:
				throw new SerializationException("Illegal escaped character: \\" + c);
			}
			buffer.append(c);
		}
		return buffer.toString();
	}
}