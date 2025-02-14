## Inspired by https://www.shadertoy.com/

import opengl, shady, staticglfw, times, vmath
let
  vertices: seq[float32] = @[
    -1f, -1f, #1.0f, 0.0f, 0.0f,
    +1f, -1f, #0.0f, 1.0f, 0.0f,
    +1f, +1f, #0.0f, 0.0f, 1.0f,
    +1f, +1f, #1.0f, 0.0f, 0.0f,
    -1f, +1f, #0.0f, 1.0f, 0.0f,
    -1f, -1f, #0.0f, 0.0f, 1.0f
  ]

var
  program: GLuint
  vPosLocation: GLint
  timeLocation: GLint
  window: Window
  startTime: float64
  vertexArrayId: GLuint

proc checkError*(shader: GLuint) =
  var code: GLint
  glGetShaderiv(shader, GL_COMPILE_STATUS, addr code)
  if code.GLboolean == GL_FALSE:
    var length: GLint = 0
    glGetShaderiv(shader, GL_INFO_LOG_LENGTH, addr length)
    var log = newString(length.int)
    glGetShaderInfoLog(shader, length, nil, log)
    echo log

proc start(title, vertexShaderText, fragmentShaderText: string) =
  # Init GLFW
  if init() == 0:
    raise newException(Exception, "Failed to Initialize GLFW")

  # Open window.
  windowHint(SAMPLES, 0)
  windowHint(CONTEXT_VERSION_MAJOR, 4)
  windowHint(CONTEXT_VERSION_MINOR, 1)
  window = createWindow(500, 500, title, nil, nil)
  # Connect the GL context.
  window.makeContextCurrent()

  when not defined(emscripten):
    # This must be called to make any GL function work
    loadExtensions()

  var vertexShader = glCreateShader(GL_VERTEX_SHADER)
  var vertexShaderTextArr = allocCStringArray([vertexShaderText])
  glShaderSource(vertexShader, 1.GLsizei, vertexShaderTextArr, nil)
  glCompileShader(vertex_shader)
  checkError(vertexShader)

  var fragmentShader = glCreateShader(GL_FRAGMENT_SHADER)
  var fragmentShaderTextArr = allocCStringArray([fragmentShaderText])
  glShaderSource(fragmentShader, 1.GLsizei, fragmentShaderTextArr, nil)
  glCompileShader(fragmentShader)
  checkError(fragment_shader)

  program = glCreateProgram()
  glAttachShader(program, vertexShader)
  glAttachShader(program, fragmentShader)
  glLinkProgram(program)

  vPosLocation = glGetAttribLocation(program, "vPos")
  timeLocation = glGetUniformLocation(program, "time")

  glGenVertexArrays(1, vertexArrayId.addr)
  glBindVertexArray(vertexArrayId)

  var vertexBuffer: GLuint
  glGenBuffers(1, addr vertexBuffer)
  glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer)
  glBufferData(
    GL_ARRAY_BUFFER,
    vertices.len * 5 * 4,
    vertices[0].unsafeAddr,
    GL_STATIC_DRAW
  )
  glVertexAttribPointer(
    vPosLocation.GLuint,
    2.GLint,
    cGL_FLOAT,
    GL_FALSE,
    0.GLsizei,
    nil
  )

  glEnableVertexAttribArray(vPosLocation.GLuint)

  startTime = epochTime()

proc draw() {.cdecl.} =
  var ratio: float32
  var width, height: cint
  getFramebufferSize(window, addr width, addr height)
  ratio = width.float32 / height.float32
  glViewport(0, 0, width, height)
  glClearColor(0, 0, 0, 1)
  glClear(GL_COLOR_BUFFER_BIT)

  glUseProgram(program)
  let now = epochTime() - startTime
  glUniform1f(timeLocation, now.float32)
  glDrawArrays(GL_TRIANGLES, 0, 6)

  # Swap buffers (this will display the red color)
  window.swapBuffers()

proc run*(title, shader: string) =

  proc basicVert(
    gl_Position: var Vec4,
    uv: var Vec2,
    vPos: Vec3
  ) =
    gl_Position = vec4(vPos.x, vPos.y, 0.0, 1.0)
    uv.x = gl_Position.x * 500
    uv.y = gl_Position.y * 500

  const
    vertexShaderText = toGLSL(basicVert)

  start(title, vertexShaderText, shader)

  # When running native code we can block in an infinite loop.
  while windowShouldClose(window) == 0:
    draw()

    # Check for events.
    pollEvents()

    # If you get ESC key quit.
    if window.getKey(KEY_ESCAPE) == 1:
      window.setWindowShouldClose(1)
