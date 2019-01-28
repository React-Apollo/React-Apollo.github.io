---
title: Chapter 5  GPU acceleration with WebGL
date: 2019-01-28 09:45
categories: IT书籍翻译
tags: [ TensorFlow.js, JavaScript,Deep Learning]
---



>Deeplearning in Broswer  Translation Demo

JavaScript代码是在中央处理器(CPU)里执行的.CPU单元速度很快,可以执行复杂的任务,但是处理任务总是以序列方式执行,这会导致一个很大的瓶颈.我们可以使用 WebWorkers来利用所有的 CPU内核,但是现代计算机很少有使用超过16核的CPU.而且,JavaScript 任然是一种解释性语言,没有和编译性语言例如C或者 C++那样性能优越.

对于深度学习计算支持最好的是 GPU.现代GPU,即使在移动设备上都有成百个处理器单元.这些单元可以同时并行工作.幸运的是,深度学习计算也可以重度依赖并行操作,因为神经元层的每个单元和同层的其他神经元都是独立的.

WebGL 深度学习实现对于处理实时的视频流是必须的. 神经网络必须要处理视频的每一帧图像,其中每帧图像都有很多像素,代表着高维度空间的一个输入向量.这个需求对于 GPU提出了特别的要求. 而且,把一个<video>(html5)元素转变为 WebGL构造很容易,也很有效,这个构造可以存储在 GPU 内存中.

WebGL 是对 OpenGL ES的 JavaScript 的绑定.到目前为止,这是唯一可以在浏览器端底层使用 GPU硬件和并行计算加速深度学习的方法.不管是由 WebGL,还是直接使用 OpenGl 的原生应用(例如 C语言),发送到 GPU的指令是相同的.

在本章,我们首先来学习一下WebGL 是如何工作的,看看如何借助它以颜色梯度形式来画出两个三角形组成的正方形. By adding a few lines of graphic code this simple color gradient is metamorphsosed into a beautiful colored Mandelbrot fractal. 接着会了解 WebGL 的威力,以及最多计算执行的位置.将会改进代码,构建第一个 GPU模拟,这是一个生命游戏 of Conway. 使用温度散射展示从离散到连续的模拟,处理精确度和优化问题. 这两个简单的问题将会帮助你理解 WebGL程序的效率,同时也会介绍 WebGL 编程模型和语言的内容.

在本章第二部分,我们会返回到深度学习,并解释实现用于常规矩阵操作的 特殊shader. 这些快速矩阵操作(例如卷积(convolution),池化(pooling),激活(activation)等等)是所有深度学习框架的基础. 我们要构建自己的GPU 线性代数库,命名为 WGLMatrix.会使用这个库来训练一个神经网络用于识别 MNIST 数据集的手写体数字,这也是图像分类里的 Hello World 程序.最后我们会优化学习脚本,使之速度比 Python/NumPy 的 CPU 版本快5倍.
![](https://ws3.sinaimg.cn/large/006tNbRwgy1fx9zk40uh4j30gq09fgn0.jpg)

WebGL 深度学习的速度用于处理事实视频流是足够快了. 这张图是借助用户的摄像头实现的 太阳镜 VR试戴系统. 卷积网络识别到面部,方位,旋转甚至是光线强弱. 然后使用这些信息画出一个眼镜的3D模型.

WebGL不是一个3D库.尽管有很多的工具可以实现3D渲染算法,整个投影处理过程需要使用单纯的矩阵操作来开发位移和摄影矩阵操作. WebGL是一个rasterization库:它会把向量对象转变为离散向量值.
![](https://ws1.sinaimg.cn/large/006tNbRwgy1fx9zlpkdqgj30gf06j3ym.jpg)
在上图左:一个向量化的猫.每个点都是向量,编码从初始点开始的位置.类似的图可以被无限的放大,但是不能直接显示在屏幕上.右图:由像素形成的图像.

正如我们在简介中学到的,WebGL通过更多的渲染通道让你可以运行繁重的并行操作. 然而和 CUDA或者 OpenGL 不同,WebGL 不是运行并行代码的通用计算 通道.因此要从并行 GPU构架中获益,我们需要把所有的深度学习相关操作变换为WebGL渲染通道. 这里的解释应该让你有了足够的动机来学习本部分内容,尤其要理解渲染通道的基本原理,shader和 GLSL.

WebGL由 Khronos集团标准化,类似 OpenGL.它的规范在[https://www.khronos.org/registry/webgl/specs.](https://www.khronos.org/registry/webgl/specs.). WebGL 的输出是在 $<canvas>$ 元素中渲染的.所以,使用 WebGL的第一步就是在web 页面的 HTML代码中插入 $<canvas>$ 元素:


```html
<body>
<canvas id='myWebGLCanvas' height='512' width='512'> </canvas>
</body>
```

页面加载以后,使用 JavaScript代码获取到 canvas 元素,创建 WebGL 上下文 *GL*.在这个节点要检测用户的配置是否和WebGL兼容:


```javascript
var myCanvas=document.getElementById('myWebGLCanvas'); var GL; //获取canvas元素
try {
GL=myCanvas.getContext( 'webgl',
{antialias: false, depth: false} );
} catch(e) {
alert('Cannot init a WebGL context. So sad...:(');
}
```

 我们已经关闭了智能感应和深层的缓存,因为我们要用 WebGL 来进行计算,而不是来执行渲染操作. 在这个操作之后, $<canvas>$ 元素 已经完全可以用于 WebGL 操作了. 不要用于 canvas2D渲染或者没有绑定 WebGL 上下文的操作.在接下来的实例中, *GL* 变量就是 WebGL  API 的接入点:所有的 WebGL 函数和属性都是 这个上下文的方法和属性.
 
 从 WebGL的视点触发,用于画图的区域叫做视口. 它的坐标系总是从中心出发,所以 X 轴是从-1(左)到1(右), Y轴从-1(底部)到1(顶部). 
 
 ###  WebGL 的工作流程
 
  WebGL 工作流划分为:
  - 主机代码,运行在 GPU,使用JavaScript语言编写.负责把几何,矩阵操作绑定到 GPU 内存,并处理用户的交互操作.
  - 图形代码,运行在 GPU,包装成称为shaders 的小段程序. 使用 GLSL,类 C 风格的语言编写(Graphic Library Shading Language).


 JavaScript 不能解析原生的 GLSL代码,所以 GLSL 源代码和变量名总是被声明为字符串,然后传递给 WebGL 上下文. 初看,这是一个很大的缺陷,然而当变量名和 TypeScript(译注:JavaScript的超语言类型,最大特点是强类型) 同时工作时,TS使用的模板字符串会极大的改进 GLSL shaders代码的可读性. 然而在本书,我们还是坚持使用原生 JavaScript.
 
 ### WebGL可以提供两种 shaders的访问权力:
 - *vertex* shader 接收几何数据作为输入,并进行变换. 操作的是 *vertex* 数据(几何向量点),可以存储在 *Vertex* 缓存对象中(VBOs). 这个shader是在 rasterization处理之前执行的.
 -  *fragement* shader 在智能感应关闭之后,每画一个像素,只能调用一次. 在resterization之后执行,会为每个输入像素插值 vertex几何向量. 对于每个像素,只渲染一次,决定这个像素的输出颜色. 

例如,如果用 WebGL 来话一个 3D 立方体:
- 立方体的每个角分别执行一次 vertex shader操作,该操作把3D位置投影到视口.
- fragment shader负责为立方体的每个像素应用颜色.

一组每个类型的 shader集合就称为 *shader* 程序. shader program 完整的定义了一个特定的渲染方法(例如, 用于3D渲染的材质).两种 shader都有相同的结构:


```javascript
//声明 I/O 变量
//定制函数
//主循环
void main(void){
//主要代码在这里
ouput_variable=value;
}
```


vertex shader 的输出变量总是 `gl_position`. 它是一个四维的向量
$[x,y,z,w]$ .in clipping坐标系中.在视口中,2D点的坐标是 $[x/w,y/w]$ . $z/w$ 缓存值的深度,在3D渲染中用于处理堆叠的深度. $w$ 是3D坐标到4D坐标同一转换的扩展,4D坐标实现仿射变换(旋转,缩放和转位操作). 可以使用单个的矩阵乘法操作执行同一坐标的仿射变换.

fragment shader的输出变量根据 GLSL 的版本不同,可以是 `gl_FragColor` 或者是 `gl_FragData` . 它是像素的 RGBA 值,RGBA 中的 `A` 代表alpha通道,所以是用来管理透明度(transparency)的. 对于标准的颜色渲染,每个颜色通道被钳位在0到1之间(例如[1,1,1,1]是不透明的白色,[0.5,0,0,1]是50%透明度的深红色,[1,0,0,1]是不透明的黑色).

![](https://ws1.sinaimg.cn/large/006tNbRwgy1fx9zmwdncqj30gx0dqq3j.jpg) 

上图是 WebGL的简化工作流程图(我们有意的去掉了 GLSL I/O类型,因为它们不可能用于 GPGPU).在左侧是数据: 用于 VBPs的 每个 vertex 数据,用于构造或者 JavaScript 数字的 类型数组. 中间是 GLSL I/O变量:他们是 GLSL和JavaScript之间的桥梁.这些变量是 JavaScript的某种指针(pointer),可以直接用在shader中.左侧是 GPU的代码. shaders之间的rasterization 有图形驱动自动执行.

### Fragment shader 渲染

我们在fragment shader中使用主要的计算. 使用两个三角形填充视口,在 fragment shader中执行所有的渲染操作. 使用 WebGL shaders 用于计算,这是最普通的练习.使用这两个三角形可以确保我们可以对每个像素执行一次fragment shader. 如果三角形没有覆盖整个视口, fragment shaders只会在三角形覆盖的部分执行. 

WebGL工作流密不可分,我们不能单独使用shader. 所以,我们也必须要使用vertex shader,但是只用来渲染两个三角形.之后,三角形每个像素的颜色由fragment shader来完成. 之后我们会用计算代替渲染.参考本书代码的第一个仓库:chapter3/O_webglFirstRendering.

### VERTEX BUFFER OBJECTS

声明一个 JS 类型数组包含视口四个角的2D坐标.


```javascript
var quadVertices = new Float32Array([
­1, ­1, //bottom left corner ­> index 0 ­1, 1, //top left corner ­> index 1
1, 1, //top right corner ­> index 2
1, ­1 //bottom right corner­> index 3 ]);
```

然后,使用 vertices 的索引把这四个点分成两组,构建出两个互相不重叠的三角形:


```javascript
var quadIndices = new Uint16Array([
0,1,2, //first triangle if made with points of indices 0,1,2 0,2,3 //second triangle
]);
```

![](https://ws1.sinaimg.cn/large/006tNbRwgy1fx9zneiaq6j30bn07ddfp.jpg)

这张图上,画出了填充视口的两个三角形.顶部靠左的为蓝色,顶点是 0,1,2.右下角红色的是 0,2,3.

数据存储在 JS 数组中.通过创建 Vertex Buffer Objects(VBO),发送给 GPU内存.VBO就是存储在 GPU内存中的的简单数组形式.


```javascript 
//send vertices to the GPU:
var quadVerticesVBO = GL.createBuffer(); GL.bindBuffer(GL.ARRAY_BUFFER, quadVerticesVBO); GL.bufferData(GL.ARRAY_BUFFER, quadVerticesVBO, GL.STATIC_DRAW);
//send indices to the GPU:
var quadIndicesVBO = GL.createBuffer(); GL.bindBuffer(GL.ELEMENT_ARRAY_BUFFER,quadIndicesVBO); GL.bufferData(GL.ELEMENT_ARRAY_BUFFER,quadIndicesVBO,GL.STATIC_DRAW);
```

### SHADER ＰＲＯＧＲＡＭ

vertex shader接收 四维的 vertices作为输入,在视口的四个角输出.这里是 GLSL中的的vertex shader源代码

```javascript
attribute vac2 position;
void main(void){
   gl_postion=vec4(position,0.,1.); position in clip coords
}
```

如上代码所示,我们只需要 Vertices 的 x和 y坐标.因此设定深度为 z=0和w=1.

接着写一个 fragment shader, 用于输出红色通道,绿色通道中每个像素的2D位置. 从现在开始,我们会经常使用这个技巧来编码输出像素的颜色通道.

```javascript
precision highp float;
uniform vec2 resolution; //resolution in pixels
void main(void){
//gl_FragCoord is a built­in input variable. //It is the current pixel position, in pixels: vec2 pixelPosition=gl_FragCoord.xy/resolution; gl_FragColor=vec4(pixelPosition, 0.,1.);
}
```


把两个 shader都声明为 JS的字符串,单独编译他们:

```javascript
//declare shader sources as string
var shaderVertexSource="attribute vec2 position;\n" +"void main(void){\n" +"gl_Position=vec4(position, 0., 1.);\n"
+"}";
var shaderFragmentSource="precision highp float;\n"

+"uniform vec2 resolution;\n"
+"void main(void){\n"
+"vec2 pixelPosition=gl_FragCoord.xy/resolution;\n" +"gl_FragColor=vec4(pixelPosition, 0.,1.);\n"
+"}";
//function to compile a shader
function compile_shader(source, type, typeString) { var shader = GL.createShader(type); GL.shaderSource(shader, source); GL.compileShader(shader);
if (!GL.getShaderParameter(shader, GL.COMPILE_STATUS)) { alert("ERROR IN "+typeString+ " SHADER: "
+ GL.getShaderInfoLog(shader)); return false;
}
return shader; };
//compile both shaders separately
var shaderVertex = compile_shader(shaderVertexSource, GL.VERTEX_SHADER, "VERTEX");
var shaderFragment = compile_shader(shaderFragmentSource, GL.FRAGMENT_SHADER, "FRAGMENT");
```


我们创建了 shader program, 包含了用于特定渲染的所有图形代码:

```javascript
var shaderProgram=GL.createProgram(); GL.attachShader(shaderProgram, shaderVertex);
GL.attachShader(shaderProgram, shaderFragment);
```

最后,用 JS 类指针变量关联 GLSL I/O变量,这个操作目的是之后可以从 JS 中更新 GLSL 的值. GLSL变量命名总是设定为字符串,因为 JS理解不了 GLSL:

```javascript
//start the linking stage:
GL.linkProgram(shaderProgram);
//link attributes:
var posAttribPointer = GL.getAttribLocation(shaderProgram,"position"); GL.enableVertexAttribArray(posAttribPointer);
//link uniforms:
var
resUniform = GL.getUniformLocation(shaderProgram, "resolution");
```


### 渲染时间

唯一在 GPGPU中使用的的 VBP 是一个四核, 所以我们可以直接绑定一次,一劳永逸:

```javascript
GL.bindBuffer(GL.ARRAY_BUFFER, quadVerticesVBO); GL.vertexAttribPointer(posAttribPointer, 2, GL.FLOAT, false, 8,0);
GL.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, quadIndicesVBO);

```


 `GL.vertexAttribPointer`  drawcall 细节是关于如何从 VBO数据中解析 shader program属性. 它意味着,`posAttribPointer` 属性(之前关联到 GLSL "position"变量) 有两个元素,类型是 `GL.FLOAT.false` 禁止对到来的 vertex 执行归一化操作,`8` 是1个vertice的字节大小(8个字节=两个元素*4字节,因为一个`GL.FLOAT`元素用4字节存储).
 
 来触发渲染吧:
 
```javascript
 GL.useProgram(shaderProgram);
//update GLSL "resolution" value in the fragment shader: GL.viewport(0,0,myCanvas.width, myCanvas.height);
//update GLSL "resolution" value in the fragment shader: GL.uniform2f(resUniform, myCanvas.width, myCanvas.height); //trigger the rendering:
GL.drawElements(GL.TRIANGLES, 6, GL.UNSIGNED_SHORT, 0); GL.flush();
 ```
 
 ![](https://ws2.sinaimg.cn/large/006tNbRwgy1fx9zo1mut5j305m05ndfo.jpg)
 
### 了解 GPU的威力

每个像素的颜色都是由fragment shader 声明 `gl_FragColor=vec4(pixelPosition,0.,1.)` 并行赋值的. 每个像素只知道由 内置变量`gl_FragCoord` 给出的相对位置. 这就是WebGL并行操作的威力.
经过渲染的像素数组纹理和 CUDA 核的渲染类似.


用下面代码替换fragment shader中的 `main` 函数.

```javascript
void main(void){
vec2 pixPos=gl_FragCoord.xy/resolution;
//translate and scale:
vec2 pixPosCentered=1.3*(pixPos*2.­vec2(1.55,1.));
vec2 z = pixPosCentered, newZ; float j = 0.;
for(int i=0; i<=200; i+=1) {
newZ = pixPosCentered+vec2(z.x*z.x­z.y*z.y,2.*z.y*z.x); if(length(newZ) > 2.) break;
z=newZ; j+=1.;
}
//generate RGB color from j:
vec3 color=step(j, 199.)*vec3(j/20., j*j/4000., 0.);
gl_FragColor = vec4(color,1.); }
```


这个漂亮的分形图渲染速度很快,因此可以在每秒60帧的的渲染循环里平滑运行.可以在github仓库 ,chapter3/1_mandelBrot 看到.
![](https://ws3.sinaimg.cn/large/006tNbRwgy1fx9zoquw23j30gq09g74t.jpg)
关于这个分形的介绍可以看 [http://nuclear.mutantstargoat.com](http://nuclear.mutantstargoat.com)网站的介绍. 仅仅使用fragment shader 就可以获得很多有趣的渲染结果,包括使用 raymarching 算法的 实时 raytracing实现. 详细内容可以参见 [http://shadertoy.com](http://shadertoy.com)

### 使用 WebGL 的通用计算

不再画漂亮的颜色梯度或者分形图, 我们来开始来处理计算. 在这一部分,要解释使用 WebGL(GPGPU) 的通用计算原理.

我们可以用使用 WebGL在两个不同的位置执行并行操作: 以fragment shader或者是 vertex shader. 在vertex shader中处理主工作负载非常不便,因为他的输出 `gl_Position`不能像 `gl_FragColor`一样直接读取或者保存在texture或者另一个对象中. `gl_Position`控制着位置,所以如果某些计算结果在视口中得到相同的位置,它们就会重叠在一起.如果滑出视口,就变为不可读. 此外,通常处理的 vertices比输出的像素要少,因此在fragment shader中的的并行计算会更有效.

再者,我们仍然会以fragment shader的输出来结束读取或者保存结果.说到 GPGPU,我们总是使用vertex shader 来简化填充视口的操作,在fragment shader中执行整个计算部分.

不再使用渲染 canvas 元素到屏幕的方法,取而代之的是渲染到所谓的 framebuffer,framebuffer 位于 GPU 的内存中,在接下来的drawcall中,使用这个framebuffer 作为texture,并从fragment shader 中读取它的值.尽管 一个texture通常被作为一个图片储存在 VRAM 中,apprehend it as a 2D array with four channels per value (which are the RGBA color channels).  它保存了计算结果,4通道可以根据任意规范来赋值.

这是一种过时的 GPGPU,因为还有非常特别的GPU计算库或者 APIS,例如 OpenGL或者 CUDA.

浏览器端热门的 JS深度学习库(例如 TensorFlow.js) 把整个深度学习模型映射到GPU的 VRAM 中,每层的输出被写入到texture,前馈至正在等待 fragment shader的下一层神经元. 我们想避免从 JS 的主线程中读取 GPU内存,而是把整个深度学习模型的执行图作为一个巨大的渲染路径.

### WebGL排错

WebGL很难排错,因为可以在不同的支持条件下执行,图形硬件之间有一些非常大的差别. 某些浏览器扩展例如 WebGL inspector或者 WebGL Insight 可以检测显卡内存是否能够链接到特定 WebGL上下文.浏览器检查texture,VBOs,或者列出drawcalls也是有可能的.

### 与硬件有关的错误

如果你遇到了硬件相关的错误,你可以:
- 打开 `chrome://gpu` 收集有关Chrome WebGL的支持情况
- 访问 webglreport.com 收集 WebGL1 和 WebGL2的支持,扩展和图形硬件限制情况.

如果 WebGL在特定规范下,怎么也不工作,可能是显卡的驱动被浏览器列入了黑名单,之所以这样是因为发现了安全漏洞. 更新驱动应该就能解决问题.

### GLSL 句法错误

当shaders 在编译的时候,会会探测可能的 GLSL 句法错误. 这些错误是显式的,有行号(以 GLSL代码的形式)声明,所以比较容易修复. 在使用 shader时, 这个错误是非常常见的.

### WEBGL 运行时错误

大多数此类错误会在标准 JS 终端中以警告的形式出现.如果一个定制的 framebuffer没有被绑定到 texture,或者 texture初始化定义的类型长度不够. 错误信息是显式的,但是 drawcall触发错误 JS 行号没有申明.

可以在 JS终端中设置断点并做分析.我建议在断点之前添加 `GL.finish()`  声明,目的是确保已经执行了所有暂停的 drawcall.

### 算法错误

这种错误很难分析,因为在 shaders中设置断点是不可能的. 要实现特殊的渲染方法以标准framebuffer的颜色通道形式显示模拟变量,借此可以高亮问题位置.

### 渲染到 texture

我们开发了 Conway的生命游戏,展示用于计算的 渲染到texture的概念.WebGL和 JavaScript 实现的游戏代码可以在本书的代码仓库中看到.运行在低级显示硬件的WebGL程序比在高端 CPU上的运行速度快4000倍.这是一个很好的例子在相对简单的代码上就可以显示并行运算的效果. 源代码在 github仓库, chapter3/x_renderToTexture

首先声明模拟的全局参数:

```javascript
var SETTINGS={
simuSize: 256, //simulation is done in a 256*256 cells //square
nIterations: 2000 //number of computing iterations
};
```

创建默认的framebuffer对象(FBO),在 WebGL上下文实例化时绑定到上下文上.渲染发生在控制显示的framebuffer上.为了渲染到texture(RTT),我们需要创建定制的framebuffer对象.然后绑定到上下文:

```javascript
var rttFbo=GL.createFramebuffer(); GL.bindFramebuffer(GL.FRAMEBUFFER, rttFbo);
```

这个函数JS类型数组创建了texture:

```javascript
function create_rttTexture(width, height, data){ var texture=GL.createTexture(); GL.bindTexture(GL.TEXTURE_2D, texture); //texture filtering:
//pick the nearest pixel from the texture UV coordinates //(do not linearly interpolate texel values): GL.texParameteri(GL.TEXTURE_2D,
GL.TEXTURE_MAG_FILTER, GL.NEAREST); GL.texParameteri(GL.TEXTURE_2D,
GL.TEXTURE_MIN_FILTER, GL.NEAREST);
//do not repeat texture along both axis:
GL.texParameteri(GL.TEXTURE_2D,
GL.TEXTURE_WRAP_S, GL.CLAMP_TO_EDGE );
GL.texParameteri(GL.TEXTURE_2D,
GL.TEXTURE_WRAP_T, GL.CLAMP_TO_EDGE);
//set size and send data to the texture:
GL.texImage2D(GL.TEXTURE_2D,
0, GL.RGBA, width, height, 0, GL.RGBA,
return texture; }
```

不可能同时读取texture和渲染它. 所以我们需要创建两个texture.两个 texture 都存储了单个红色通道的 细胞声明(如果细胞是活的,红色通道的值就是1.0,如果死了,就等于0.0):

```javascript
var dataTextures=[ create_rttTexture(SETTINGS.simuSize,SETTINGS.simuSize,data0), create_rttTexture(SETTINGS.simuSize,SETTINGS.simuSize,data0)
];
```

`data0`是随机初始化的`UnitArray`,储存了texture的 RGBA值.
在第一次模拟遍历期间,使用`dataTexture[0]`渲染到`dataTexture[1]`,接着交换两个texture,然后重新遍历.

我们需要两个shader程序:
 
 - 计算shader 程序接受细胞状态 texture作为输入,并返回更新的细胞状态.
 - 在模拟的末尾,渲染的shader程序使用一次,用于在画布上显示结果

两个shader 程序需要同样的vertex shader,仍然画出两个三角形填充视口.所有的逻辑执行都通过fragment shader执行.

这里是计算fragment shader的主函数. 实现了Conway 的生命游戏:

```javascript
void main(void){
//current position of the rendered pixel:
vec2 uv=gl_FragCoord.xy/resolution;
vec2 duv=1./resolution; //distance between 2 texels //cellState values: 1­>alive, 0­>dead:
float cellState=texture2D(samplerTexture, uv).r; //number of alive neighbors (Moore neighborhood): float nNeighborsAlive=
texture2D(samplerTexture, uv+duv*vec2(1.,1.)).r
+ texture2D(samplerTexture, uv+duv*vec2(0.,1.)).r
+ texture2D(samplerTexture, uv+duv*vec2(­1.,1.)).r + texture2D(samplerTexture, uv+duv*vec2(­1.,0.)).r + texture2D(samplerTexture, uv+duv*vec2(­1.,­1.)).r + texture2D(samplerTexture, uv+duv*vec2(0.,­1.)).r + texture2D(samplerTexture, uv+duv*vec2(1.,­1.)).r + texture2D(samplerTexture, uv+duv*vec2(1.,0.)).r;
if (nNeighborsAlive==3.0){ cellState=1.0; //born
} else if (nNeighborsAlive<=1.0 || nNeighborsAlive>=4.0){ cellState=0.0; //die
};
gl_FragColor=vec4(cellState, 0., 0.,1.);
}
```


`texture2D` 声明从texture(也称为一个texel)获取一个像素.它的参数是texture 赝本和texel 坐标. 根据GPU的能力强弱,在 一个fragment shader中大概可以同时使用16个texture. 确切的数字可以通过声明获得.

`GL.getParameter(GL.MAX_TEXTURE_IMAGE_UNITS)`. 当然你可以实例化更多的texture,但是不能都同时使用. 样本在 shader中有类型 `uniform sampler2D` 但是赋值有点想 JS 的整数:

```javascript
//At the linking step
var _samplerTextureRenderingUniform=GL.getUniformLocation( shaderProgramRendering,'samplerTexture');
//...
//We affect the sampler value to channel 7, like an integer GL.useProgram(myShaderProgram); GL.uniform1i(_samplerTextureRenderingUniform, 7);
//...
//Just before the rendering:
//we activate the texture channel 7: GL.activeTexture(GL.TEXTURE7);
//we bind myTexture to the activated channel: GL.bindTexture(GL.TEXTURE_2D, myTexture);
```


GLSL的第二个参数声明 `texture2d`是 textures坐标,也称为UV坐标.
它是 `vec2`的实例,标记获取的texel的位置.它的两个元素都在 0.0-1.0之间.

来准备一下模拟步骤:

```javascript
GL.useProgram(shaderProgramComputing);
GL.viewport(0,0,SETTINGS.simuSize,SETTINGS.simuSize);
```


接着加载模拟循环:

```javascript
for (var i=0; i<SETTINGS.nIterations; ++i){
//dataTextures[0] is the state (read): GL.bindTexture(GL.TEXTURE_2D, dataTextures[0]); //dataTextures[1] is the updated state (written): GL.framebufferTexture2D(GL.FRAMEBUFFER,GL.COLOR_ATTACHMENT0,
GL.TEXTURE_2D, dataTextures[1], 0); GL.drawElements(GL.TRIANGLES, 6, GL.UNSIGNED_SHORT, 0);
dataTextures.reverse(); }
}
```



`GL.framebufferTexture2D(...)`意味着在当前framebuffer 范围之内(就是`rttFbo`)画出的每个内容也要滑入到texture `dataTextures[1]`.

以渲染步骤结束:

```javascript
//come back to the default FBO (displayed on the canvas):
GL.bindFramebuffer(GL.FRAMEBUFFER, null); GL.useProgram(shaderProgramRendering); GL.viewport(0,0,myCanvas.width, myCanvas.height); //[...]
//trigger the rendering:
GL.drawElements(GL.TRIANGLES, 6, GL.UNSIGNED_SHORT, 0); GL.flush();
```

![](https://ws1.sinaimg.cn/large/006tNbRwgy1fx8givnbpkj30go087mx6.jpg)

上图是 Conway 生命游戏的模拟结果.在仓库代码中,我们已经修改了初始值,从模拟中心(左边图)开始的活细胞呈现方形.经过2000轮迭代之后,复杂图形出现了(右图).

### 精确度的重要性

在 Conway游戏中,我们只使用离散值:细胞要么是活要么是死.但是如果你需要使用连续值,你就有可能被 WebGL默认的八位精确度限制住.事实上,,每个`gl_FragColor`的元素都是用八位编码,并且被钳位在0~1之间.每个元素的值只有  $2^8=256$ 中可能性. 这对于颜色编码就足够了,因为人眼不能分辨一个比特的颜色差异. 但是在深度学习模型中我们需要更高的精确度,因为经常需要处理浮点值.16比特的浮点值(`GL.HALF_FLOAT`)可能就够了.但是某些配置只有32比特精确度(`GL.FLOAT`)才能使用.需要以下能力:

-  `FLOAT`或者`HALF_FLOAT` texture的 实例化
-  渲染 texture 到 `FLOAT`或者`HALF_FLOAT` texture


如果你使用 $WebGL_1$,就需要 `OES_TEXTURE_FLOAT`或者`OES_TEXTURE_HALF_FLOAT` 扩展(并不总是能实现).接着仍然需要测试 渲染到 `FLOAT`或`HALF_FLOAT` texture


如果使用 $WebGL_2$  这些需求已经满足了,因为 `FLOAT`或`HALF_FLOAT` 已经包含在规范中. 但是只有渲染到texture,到`HALF_FLOAT` texture 是规范声明的. $WebGL_2$可以向后兼容$WebGL_1$,通过使用:

```javascript
 var GL=myCanvas.getContext('webgl2', ...);
```

在上下文初始化里,应该要执行:

- 如果使用 $WebGL_2$ ,就是用 具有`HALF_FLOAT`精确度的 $WebGL_2$
- 如果使用 $WebGL_2$:
   -- 得到 `OES_TEXTURE_HALF_FLOAT` 扩展
   -- 使用 `FLOAT` textures 测试 RTT.

- 如果`OES_TEXTURE_FLOAT` 扩展不可用或者 如果 `RTT`不工作:
   -- 获取 `OES_TEXTURE_HALF_FLOAT` 扩展
   -- 测试 RTT

在某些 GPU 配置中,我们需要得到 `<WEBGL|EXT|OES>_color_buffer_float` 扩展.否则就不能把framebuffer 对象绑定到 `FLOAT`或者`HALF_FLOAT` texture.

在着色中使用的精确度要在第一行确定:

```javascript
precision highp float
```

它接收三个值:
- `lowp` : 计算由八位精确度完成. 速度足够快,但是对于浮点数计算不够精确. 仍然适合于渲染颜色值.
- `medium:highp,lowp`或者位于两者之间的精确度,但这要看 GPU 的配置.在使用这个水平的精确度之前,需要使用`GL.getShaderPrecisionFormat(GL.MEDIUM_FLOAT)` 检测真实的精确度,因为随着显卡的不同,精确度会发生变化.
-  `highp` : 浮点值使用 16或者32比特 来处理.16比特用于深度学习计算就够了(但是并不总是能用于物理模拟...). 这个水平的真实精确度可以通过运行 `GL.getShaderPrecisionFormat(GL.HIGH_FLOAT).`检测

`GL.getShaderPrecisionFormat(<level>)` 的返回值包含有 `precision` 属性的对象,属性值是 编码着色时浮点数小数部分的位数.例如,32位浮点数就是23,16位的浮点数就是10.


 从Conway开始,开发一个热图模拟.包含 浮点 textures.可以在 Github 仓库 ,chapter3/3_RTTfloat.  我们模拟了一个2D的方形铁块,边长是2.56米,温度是100 $o^oC$ .周围由   0 $o^oC$ 的铁块包围,热量随时间散失. 
 
 ![](https://ws2.sinaimg.cn/large/006tNbRwgy1fx8ibr0y1hj30gm08c3yx.jpg)
 
 在这幅图中, 左侧:模拟了初始状态,右侧:模拟了2000秒之后的情况. 颜色由 IDL_Rainbow color 图实现,使用fragment 着色,从0~100  $o^oC$  平衡
 
 ### 优化
 
 使用 WebGL 来实现深度学习网络不太容易.导入了一些复杂的内容,原因是 特定的工作流和依照不同图形硬件而实现的不同执行路径引起. 仅有的目标是提高执行效率,这可能称为一些效率低下代码的遮羞布.
 
 再者说, 速度的确对很多用例很重要. 计算机视觉问题,例如图像分类,分隔或者物体识别,总是针对连续视频流工作,在视频流中要维持 每秒30帧(FPS)的速度.因此,应该要遵循一些基础着色原则.
 
 #### GLSL 开发
 
 和你想的的一样, GLSL开发是整个书的主题(最流行的部分,覆盖率超过1.000页!). 我们会处理一些常见的开发错误. 如果你想更进一步的学习 WebGL 和 GLSL ,你可以尝试 [http://webgl.academy](http://webgl.academy) 的免费交互课程.
 
 在有可能的情况下,要避免在着色时使用条件声明语句,例如:`if...then...else`. 思考一下这段计算指数线性单元(ELU) 激活函数:
 
```javsascript
 float ELU(float x){ if (x>=0.0){
return x; } else {
return exp(x)­1.0; }
}
```
 
使用的是 `if` 声明. 这样做,这段代码会更有效:

```javascript
float ELU(float x){
return mix(exp(x)­1.0, x, step(x, 0.));
}
``` 



GLSL内置函数`mix()`,定义为:  
   $mix(x,y,a)=x*(1-a)+y*a$
   
   
使用几个较小的着色器代替单个大的着色器. 如果着色器太长,GPU 的执行缓存会在执行期间发生更新,这就会有拖累.

### 注意浮点的特殊性

在高精度的着色器上,浮点数根据 GPU不同,使用16比特或者32比特存储.第一位决定符号,之后的位置,对于32位编码,8比特编码指数,23比特编码分数.因为有这个存储方式,32位编码的浮点数最大是 `3.4e38`,最小是`-3.4e38`. 对于16位编码,这个范围要更窄一点.

![](https://ws2.sinaimg.cn/large/006tNbRwgy1fx8rnjzng5j30gu0400sq.jpg)

本图是32位二进制编码形式.来源:Wikipedia
如果计算结果超过了上面的最大值,会被特殊的浮点数替换,`+Infinite`. 怎么处理特殊浮点数例如 `+Infinite`,`-Infinite`,`NaN`,不同硬件策略不同. 接着值计算结果在计算流程中继续传递.

特殊的浮点数被存储在`FLOAT`和`HALF_FLOAT` 纹理中.所以如果我们要把结果渲染到纹理,这些特殊值要经过如下的计算.

特殊浮点即使在计算步骤是隐式条件下也会出现.考虑一下计算 ELU激活函数的 GLSL 函数:

```javascript
float ELU(float x){
return mix(exp(x)­1.0, x, step(x, 0.));
}
```


如果 `x=100`, 这是有可能的结果(x 可以是输入神经元权重的总和),我们得到  `ELU(100)=100`. 但是 GPU 必须要计算 `ELU(100)=mix(exp(100)-1,100,1)=(exp(100)-1)*0+100`. 但是 exp(100)= $2.7.10^43$ 超过了浮点最大值. 所以用特殊浮点值 `+Infinity` 代替. `exp(100)-1=+Infinity-1=+Infinity` . GPU 计算的 `ELU(100)=+Infinity*0+100`.但是 `+Infinity*0`是未定义的,但是它生成了另一个特殊浮点数,`NaN`. `NaN`总是会沿着操作流程传递,因为任何包含有 `NaN`的操作都会输出`NaN`(相反,`Infinite`会消失,因为 1/Infinity=0) .GPU输出 `ELU(100)=NaN+100=NaN`.接着所有下一层连接的神经元收到 `NaN`值,然后也输出`NaN`,等等一直继续.

有一些解决办法可以避免出现特殊浮点值:
- 避免在函数中包含指数(例如, softmax)或者对数.有时候可以用多项式代替.
- 如果 `mix()` 或者其他的 GLSL插值函数被调用,确保两个参数都足够小. 这样实现 ELU 更安全:

```javascript
float ELU(float x){
return mix(exp(­abs(x))­1.0, x, step(x, 0.));
}
``` 


- Majorate or minorate.
- 使用深度学习技术把权重和偏置保持在较低的值,例如 L1或 L2 正交化.


关于因伟达GPU特殊浮点数的规范都可以在官网上看大.


### 重视 纹理缓存

GPU 有类似 CPU 的多层缓存系统.当纹理素材是通过 `texture2D()`函数声明在片元着色器中获得,GPU 首先会搜索较小但是速度快的缓存. 如果没找到,它会触发一个缓存缺位,接着再第二级稍大,但是速度慢的缓存中查找,直到在最高级的纹理缓存中获取素材信息为止.接着纹理素材被拷贝进底层的高速缓存,在接下来的查找时,速度会加快.

如果临近的像素使用的是同样的纹理素材渲染 ,缓存的缺失率很低,着色会加快.但是如果临近像素使用不同的纹理素材, 缓存确实会增加,着色执行效率会显著下降.在一些实例中,有很多方法可以在纹理中安排数据. One of the alternatives is often better optimized for this aspect.


![](https://ws3.sinaimg.cn/large/006tNbRwgy1fx8xyfb81bj308e08gq3e.jpg)

上图看到的是图形内存, 纹理素材不整齐,但是是以莫顿顺序排列的. 这个处理被称为纹理swizzling. 获取纹理之后,纹理素材的整个线条(显示为红色) 被压入到 GPU 缓存中. 所以 2D的近邻纹理素材获取速度会更快,因为可以在底层的缓存找到.

尽管有一些书籍谈到了 纹理缓存(纹理缓存, Michael Dogget ,Lund University) ,缓存实现机制还是因硬件不同而有区别.仍然需要使用不同的硬件测试 WebGL程序,保证它可以在任何地方都可以运行,而且保持足够快的速度.

### 颜色通道角色

渲染到纹理定义了四个颜色通道和四个颜色通道帧缓存. 他们以不同的方式使用:

- 只有一个通道被使用,像 Conway 游戏模拟一样. 但是他不能被优化,因为 GPU无论什么时候都会同时处理四个向量和矩阵.所以我们要为相同的操作执行四次计算.
- 每32比特的值可以分包进四个 RGBA 8比特元素中.之后这些元素可能根本不会用于浮点纹理. 主要的缺陷是 每个片元着色器应该从纹理解压缩出的 RGBA 值应该是32比特的值,然后压缩为`gl_Fragcolor`的 8比特 RGBA通道.
- 四个神经元网络可以并行运行在四个 RGBA 通道上. 四个神经元学习的是不同的初始参数,输出稍有不同.输出结果是四个神经元网络的平均值. 并行的四个通道有助于减少输出的噪音.

### 防止抖动

WebGL 状态可以通过使用`GL.enable()`或者`GL.disable()` 指令来修改. 他们的状态会被保留.所以 WebGL上下文的状态需要改变一次. 在片元着色器用于计算时,抖动要关掉,因为它有可能会改变输出值. It consists in applying some noise to the fragment shader output to avoid color quantization visual artifacts.

```javascript
GL.disable(GL.DITHER);
```

![](https://ws2.sinaimg.cn/large/006tNbRwgy1fx9m0r93mvj30gp05mt9r.jpg)

在这张图上,可以看到如果分辨率比计算的颜色精度低,抖动就会在framebuffer中改变颜色像素值.在左边:图像是32比特 RGBA 颜色.中间:2比特 RGBA 颜色.颜色精度降低,猫的每个像素由调色板中最类似的颜色代替. 右边图也是2比特的颜色,但是打开了抖动. 像素颜色不在是调色板中最近似的颜色:为了避免出现边界,引入了一些噪声.

### 避免帧缓存交换

使用`GL.framebufferTexture2D`,实例化一个帧缓存,每次需要渲染到特定的纹理时,在其上动态绑定的做法比使用`GL.bindFramebuffer`有效率的多,使用`GL.bindFramebuffer`时,每次渲染一个纹理,都重新实例化一个新的framebuffer. 的确,`GL.bindFramebuffer`执行的计算开销非常大.

### 一个三角形比两个更好

相比在视口上画出两个三角形,我们更愿意画出单个更大的三角形(定点是:[-1,1],[3,-1],[-1,3]).单个大三角形的速度稍快一点. 片元着色器仍然是针对每个像素执行一次,感谢 WebGL 整合进图形流水线的 $scissor$ 测试,使之成为默认的的选项.

### 从CPU到GPU,再从 GPU到 CPU

在一开始,数据不管是图片,视频还是数组都由Javascript处理,所以它们注册,并存储在 CPU的内存汇总,首先由 CPU 处理. 接着被发送到 GPU,使用 GPU 的着色器处理.最后可能在 CPU端再次使用到经过着色的数据.所以我们需要把数据从 CPU发送到 GPU,接着数据原路返回.

### 浮点纹理初始化

浮点纹理从 JavaScript数据初始化而来.例如,如果突出权重被存储在纹理中,我们 会使用从之前训练或者匹配特定随机分布获取的 JavaScript 数组值来填充纹理. 如果纹理储存了 `GL_FLOAT` 元素(每个浮点数使用32比特),初始化是简洁明了的:

```javascript
//small variation between WebGL1 and 2:
var internalPixelFormat=(ISWEBGL2)?GL.RGBA32F:GL.RGBA; GL.texImage2D(GL.TEXTURE_2D, 0, internalPixelFormat,
<width>, <height>,
0, GL.RGBA, GL.FLOAT, <instance_of_Float32Array>);
```


但是如果纹理存储的是`GL.HALF_FLOAT`类型,从数组的初始化就很难了,因为 JavaScript 没有 `Float16Array`类型. 在 JavaScript 端,我们必须要使用每值16比特的形式编码浮点数(1比特符号,5比特指数,10比特分数). 接着要把编码数据存入 JavaScript `Unit16Array`中. 在本书的仓库中有 JS函数编码 `Float32Array-Unit16Array`的方法(参见 RTTfloat 热图模拟).  接着使用`Unit16Array` 来初始化纹理:

```javascript
//see "continuous simulation" example to see the code
//of the "convert_arrayToUInt16Array" function:
var u16a = convert_arrayToUInt16Array(<instance_of_Float32Array>); var internalPixelFormat=(ISWEBGL2)?GL.RGBA16F:GL.RGBA;

GL.texImage2D(GL.TEXTURE_2D, 0, internalPixelFormat, <width>, <height>,
0, GL.RGBA, GL.HALF_FLOAT, u16a);
```


### 在 CPU 获得返回的计算结果

除非我们的工作流是100%的 GPU流程,否则在有些情况下,我们需要把计算结果返回到JavaScript中.这个操作很慢,能不操作就不操作. 必须要渲染到默认的framebuffer(显示在<canvas>元素中),然后使用`GL.readPixels`指令读取像素值.它使用一个正方形区域的的交错像素 RGBA 值来来填充 JavaScript 的 `Unit8Array`. 速度慢的根源是 CPU 和 GPU之间要强制同步. 在使用之前我们应该要使用选项 `preserveDrawoingBuffer:true` 来创建 WebGL 上下文.


读取8bit的编码值是很直接的:  片元着色器把纹理值拷贝到`gl_FragColor`,然后进行渲染.接着 framebuffer的值通过`GL.readPixels` 读取. 但是对于浮点值纹理,过程更加复杂. 需要开发特殊的片元着色器把每个浮点值打包成几个8比特的值,然后使用栅格视口来处理几个渲染过程, 使用 `GL.readPixels` drawcall 读取渲染数据,最后使用 JavaScript 的 `Unit8Array` 重构浮点数组.

在本书代码仓库中有着色器把浮点数打包成8比特颜色值的代码,同时还有读取浮点纹理的示例代码.

## 用于矩阵计算的纹理和着色器

经过一段在 WebGL和 GPGPU 的奇妙旅行,我们要返回到深度学习中,构建一个最小的 WebGL 线性代数库`WGLMatrix`. 接着我们会使用这个库来实现一个简单的神经网络(非卷积网络),学习识别MNIST数据集的手写体数字. 第一版本的线性代数库包含在仓库 chapter3/4_WGLMatrix.


### 标准矩阵加法

在 GLSL中内置的矩阵类型最大只支持4个维度. 这对于深度学习是远远不够的. 所以矩阵要 用纹理来存储,我们需要开发特殊的纹理用于常见的矩阵操作. 每个 texel 都是一个矩阵条目,纹理的分辨率和矩阵的维度是一样的.

在创建矩阵时,如果 JavaScript 提供了初始化数组,RGBA 通道就用这些数组填充.否则,如果只提供了一个数组,它的值就会被复制四次用于填充颜色通道. 每个普通的矩阵操作在 RGBA 颜色通道中都是独立执行的.也就是我们可以对一个数组使用四个不同矩阵并行处理四次.

加法片元着色器不会和其他元素类操作符一样依赖于矩阵的大小.这是 GLSL 的代码:

```javascript
void main(void){
vec2 uv=gl_FragCoord.xy/resolution;
vec4 matAValue=texture2D(samplerTexture0, uv); vec4 matBValue=texture2D(samplerTexture1, uv); gl_FragColor=matAValue+matBValue;
}
```


### 标准矩阵乘法

和加法着色器不同,乘法着色器包含了`for` 循环用于遍历第一个矩阵的行和第二个矩阵的列.使用 $WebGL_1$ 不能在`for` 条件语句中使用 非常量值.这限制了GLSL的归一化值或者之前计算结果的使用.所以我们需要为每个矩阵乘法维度编译一个着色器程序. 例如,这段代码用于 (n,10)矩阵和(10,n)矩阵的所有乘法:

```javascript
//vector between 2 consecutive texels of first factor:
const vec2 DU=vec2(1./10., 0.);
//vector between 2 consecutive texels of second factor: const vec2 DV=vec2(0., 1./10.);
void main(void){
vec2 uv=gl_FragCoord.xy/resolution; vec2 uvu=uv*vec2(1.,0.);
vec2 uvv=uv*vec2(0.,1.);
vec4 result=vec4(0.,0.,0.,0.);
for (float i=0.0; i<10.0; i+=1.0){
result+=texture2D(samplerTexture0, uvv+(i+0.5)*DU) *texture2D(samplerTexture1, uvu+(i+0.5)*DV);
}
gl_FragColor=result; }
```


增加了 0.5 到 i 用于提取像素中间值,否则可能会在特定的矩阵维度上出现舍入错误. 在  $WebGL_2$ 中, 实现了`for`循环中的非常量操作,但是商业应用对于 $WebGL_2$ 的支持仍然是不可接受的(2018年3月的支持率是41%,webglstats.com数据).所以我们要构建一个 $WebGL_1$ 着色器,也可以用于 $WebGL_2$ 操作.

我们经常会同时进行矩阵乘法和加法. 例如,把一个神经元层的输入 $x$ 和权重矩阵 $W$ 相乘,然后加上偏置 $B$,可以计算出总的输出 $Z:Z=Wx+B$ .
应该要编译一个特殊点着色器用于执行这个操作,称为 FMA(Fused Multiply-Accumulate,熔合乘法累积).它会节省一些渲染到纹理的时间.

我们的矩阵库,`WGLMatrix`, 管理者一个乘法和 FMA程序的字典.如果我们需要处理两个矩阵,这是字典中包含的普通维度操作,我们只使用字典中的着色程序就可以了.否则会编译出具有新维度的着色器程序,并添加到字典中.

### 激活函数的应用

着色器就是专门用于激活函数的应用. 我们应该要小心特殊浮点数,尤其是包含指数或者对数的激活函数. 下面的着色器使用 sigmoid 激活函数:

```javascript
const vec4 ONE=vec4(1.,1.,1.,1.); void main(void) {
vec2 uv=gl_FragCoord.xy/resolution; vec4 x=texture2D(samplerTexture0, uv); vec4 y;
y=1./(ONE+exp(­x));
gl_FragColor=y;
}
```
因为很多的特殊激活函数都可以应用于矩阵,我们设置了公用的方法从外部库编译定制的着色器.

### 精通 WGLMatrix

矩阵在使用之前需要初始化, 矩阵 `m,v,n`从扁平值开始初始化:

```javascript
// encoding 3*3 matrix | 0 1 2 |:
// |345|
// |678|
var M=new WGLMatrix.Matrix(3,3,[0,1,2, //V is a column matrix, which is a vector: var V=new WGLMatrix.Matrix(3,1,[1,2,3]);
3,4,5, 6,7,8]);
var W=new WGLMatrix.MatrixZero(3,1);
```

从数学角度说, 向量和矩阵没有区别,向量就是宽度为1的矩阵.经过初始化,我们就可以对矩阵进行操作. 为了对矩阵`A` 执行操作 `OPERATION`,运行:

```javascript
 A.OPERATION(arguments..., R)
```

`R`是用于结果储存的矩阵.我们不能把结果存储在任何用于操作的矩阵中,因为不可能同时读取纹理和渲染纹理. 操作总是返回结果矩阵 `R`.


例如,处理操作 $W=M*V$ ,运行代码:

```javascript
M.multiply(V,W);
```

结果返回一个矩阵 $W$.我们可以声明一个定制元素的操作:

```javascript
WGL.addFunction('y=cos(x)','cos');
```

GLSL函数代码中,使用预定义的 `vec4 x*vec4 y`. 第二个参数是用户定义的函数标识符. 然后应用于矩阵 `M`的元素,执行操作 `M.apply('COS',R)`  这里的R 是矩阵收到的结果.

##  应用于手写体识别

我们已经在 WGLMatrix 中添加了一些实现训练和运行神经网络的矩阵操作方法
.也添加了一些验证矩阵维度的方法,防止无效的操作发生.

### 数据编码

GPU加载的数据集作为输入向量,编码了数字图像,等待输出结果.数据集使用了显卡内存的绝大多数.这些数据不需要16或者32位精度:8位就足够了,因为输入图像使用8位编码每个通道的.输出是二元值.

我们已经在 WGLMatrix库中添加了8位精度的支持.

数据加载使用`mnist_loader_js` 脚本. 在代码第50行,添加了新的[X,Y]对,根据索引存储训练或者是测试数据集:

```javascript
targetData.push([
new WGLMatrix.Matrix(784, 1, learningInputVector), //X new WGLMatrix.Matrix(10, 1, learningOutputVector) //Y
}
```


这一步之后,整个数据集作为纹理被加载到显卡内存中

### 内存优化

能够预测需要的显卡内存就很重要了,如果我们要分配比可用内存多的内存,WebGL上下文进程会被杀掉,应用会崩溃.在我们的实例中,我们加载了 `60000`幅手写数字图片,所有有 $6000*28*28=47e6$的纹理素材. 每个texel存储在4个 RGBA通道,每个颜色通道使用8比特来编码(1字节). 我们需要 `47e6*4*1=188e6`字节用于输入向量,所以大概是200MB,对于输出向量,我们需要 `60000*10*4*1=2.4e6`字节,大概是2.4MB.

但是 GPU不支持以原生像素形式存储纹理. 每个像素根据2D坐标上的近邻来编码,所有有很强的边缘效应.在我们的实例中,没有使用大约400MB的显卡内存,整个数据集需要4G 的显卡内存.

![](https://ws2.sinaimg.cn/large/006tNbRwgy1fx9q0kf5g7j30gb0d0my6.jpg)

上图中,你看到的是 英伟达的 GPU,这里,英伟达的设置面板对于检测 GPU内存和占用率很方便.完成整个 MNIST 数据集加载之后,你可以看到使用93%的显卡内存.

如果把输入像向量的外观从(784,1)变为(28,28), 他们的内存大小是一样的,因为他们支持的问题有相同到的纹理像素(784*1=28*28).但是这时,整个 MNIST 的数据集占用的显存大概只有280MB,所以少了10倍.的确,一个像素宽的纹理像素例如(784,1)的输入向量存储效率不高,因为纹理像素都没有2D的邻居. 正方形的纹理像素仍然高于理论值,因为内存是分页的(或者分成单个的块),并且有边缘效应,因为这些纹理后很小.

为了优化 GPU 纹理的压缩,我们需要:
- 使用的纹理要尽可能的是方阵
- 纹理相乘获得一些大的纹理,称为纹理地图集

如果我们分配了一些大的正方纹理,边际效应减小,部分内存块的空余会减小.实际占用的内存值会更接近于理论值. 为了保持实现简单一点,我们不考虑这些改进措施.总是使用和分辨率和编码矩阵维度相同的纹理.

### 前置
这是在network.js中声明的sigmoid函数:

```javascript
 WGLMatrix.addFunction('y=1./(ONE+exp(­x));', 'ACTIVATION');
```


这是 network.js中的前置部分:

```javascript
self.feedforward=function(a){
//Return the output of the network if ``a`` is input. for (var i=0, inp=a; i<self._nConnections; ++i){
//from input to output layer,
// compute WI+B and store the result in _z: self.weights[i].fma(inp, self.biases[i], self._z[i]);
//apply actFunc to _z and store result to _y
self._z[i].apply('ACTIVATION', self._y[i]);
//set input for the next iteration
inp=self._y[i]; }
return inp; }
```


### 第一次尝试

我们已经把使用 Python/Numpy写的 MNIST分类器转码为 JavaScript/WGLMatrix. 代码可以在 chapter3/5_MNIST 查看. 这段代码来自于 Micheal Nielsen的在线书籍 <神经网络和深度学习>第一章.  地址是[http://neuralnetworksanddeeplearning.com/chap1.html](http://neuralnetworksanddeeplearning.com/chap1.html)

分类器的神经网络是非常浅显的. 它只有三层神经元:

-  输入神经元有784个单元(接收28x28像素的数字图像)
-  隐藏层有 30个神经元
-  输出层有10个神经元(每个数字一个)

属于致密连接,激活函数是 sigmoid.网络训练超过30个epochs,每个小批次有8个样本,学习率是3.0(每个小批次). 训练集有50 000个样本,测试集有10 000个样本.最佳效果是27个epochs的95.42%

这是基准值:
- Python/Numpy 实现(Python=2.7.12,CPU=Intel Core i7-4720HQ):318秒
- JavaScript/WebGL实现(Chrome=65,GPU=Nvidia GTX960M):942秒

注释: 通过 Numpy执行的矩阵操作是使用底层的线性代数库,例如 BLAS或者 LAPACK实现,它们有类似 SIMD 的指令,使得使用 CPU 的执行也很有效.
如果使用原生的 Python 函数,会更快.

这个基准中,我们的实现不太好,但是我们可以通过一些改进超越Numpy 的实现

### 改进执行效率

可以看 改进的版本  在 chapter3/6_MNISTimporved

在之前的实现中,我们完全没有使用 RGBA 通道. 操作毫无用处的在四个通道中被复制了.这里要单独使用四个通道,从而可以并行处理四个输入向量.这是可行的,因为最小批次是4的倍数(之前的例子中是8).对于测试数据,为了多路复用RGBA通道,我们把每4个输入/输出向量包装成一个输入/输出向量.同样的执行,现在的实现时间从942秒下降到282秒. 现在比 Python/Numpy更好了.

但是 GPU 的利用率只有30%,因为纹理编码矩阵太小.的确,如果我们渲染的纹理的尺寸小于 GPU 计算单元数量时就会出现瓶颈:没有足够的工作可以做,一些计算单元处于休眠状态.

所以,我们需要渲染更大的纹理.有几个方案可以解决这个问题:

- 把几个小的批次样本分组成一个纹理.和我们在 RGBA通道对于小批量样本的复用一样,分组的纹理包含纹理的空间复用. 这个方案加速了学习,但是没有改善
  网络的利用效率.
- 可以增加每层神经元的数量. 核心的概念是使神经网络的构架适应硬件构架.我们选择这个方案.

考虑一下另一种学习 MNIST数据集的网络构架:

- 输入层有784个单元(接收28X28像素的数字图像)
- 两个隐藏层,分别有256和64个神经元
- 输出层有10个神经元(每个数字一个)


每批次8个样本,学习率1.0. 超过20个epoch. 现在 GPU的占有率平均在64% .我们的方案执行时间是344秒,Python/Numpy的执行时间为1635秒,几乎快乐5倍(最佳成功率在epoch18,96.45%). 通过增加隐藏层神经元规模,还可以增加 GPU的使用强度到100%  我们的方案和 Python方案的执行比值会攀升的更高.但是在测试数据上不会得到更好的结果,因为过拟合问题(应该要实现正交化或者丢弃算法来解决过拟合问题,后者实现卷积连接).

使用低端 GPU(笔记本电脑的低端 Intel HD4600 GPU),同样的学习花费587秒.仍然比 CPU的实现快了3倍.


## 总结

本章我们从 WebGL的简单实现开始,画出两个三角形填充视口. 在开始 WebGL 的学习曲线很陡,这是最难的部分. WebGL似乎很繁琐,我们需要写很多代码,渲染 之前要创建不同的对象.但是实践的越多,它展现的逻辑越多,便利性也越大.经过首次渲染后,学习变成增量式的了.

接着,我们使用 WebGL来计算并行像素颜色,形成了漂亮的分形. 尽管每个像素都要经过重度的计算,但是渲染速度很快.之后,我们利用这个能力来加速计算. 实现渲染到纹理,得到结果用于下一步使用,代替了直接的显示. 实现类第一个 WebGL模拟: Conway 生命游戏.

我们处理了浮点计算问题. WebGL 设计时就考虑的是低精度计算,因为 RGB 颜色值每个元素不需要使用超过8比特的编码.所以我们要根据显示硬件版本和 WebGL 版本来考虑几个不同的执行路径. 运用新的知识,把之前的模拟转化为温度散失模拟,用物理连续变量代替了离散变量.

构建了自己的线性代数库,可以操作所有标准的矩阵操作.用它测试了 MNIST 数据集的手写体识别模型. 最后,我们优化了模型的实现,使之比 Python/Numpy的版本更快.

这一章对于改进已有的 WebGL 实现或者构建定制的 WebGL 实现都特别有用.无论我们如何在 WebGL上叠加任何的软件,如果不理解底层的机制,正确优化或者有效添加功能都是不可能的.这也是一个起点,开启了实际应用硬件加速的无限可能.

在下一章,我们将会看看如何从浏览器提取数据,例如从 URLs 加载图片,从摄像头解析帧图像,或者解析话筒拾取的音频.


