function t(t,e,r){t.prototype=e.prototype=r,r.constructor=t}function e(t,e){var r=Object.create(t.prototype);for(var n in e)r[n]=e[n];return r}function r(){}var n=.7,a=1/.7,i="\\s*([+-]?\\d+)\\s*",o="\\s*([+-]?\\d*\\.?\\d+(?:[eE][+-]?\\d+)?)\\s*",s="\\s*([+-]?\\d*\\.?\\d+(?:[eE][+-]?\\d+)?)%\\s*",u=/^#([0-9a-f]{3,8})$/,l=new RegExp("^rgb\\("+[i,i,i]+"\\)$"),h=new RegExp("^rgb\\("+[s,s,s]+"\\)$"),c=new RegExp("^rgba\\("+[i,i,i,o]+"\\)$"),g=new RegExp("^rgba\\("+[s,s,s,o]+"\\)$"),d=new RegExp("^hsl\\("+[o,s,s]+"\\)$"),f=new RegExp("^hsla\\("+[o,s,s,o]+"\\)$"),p={aliceblue:15792383,antiquewhite:16444375,aqua:65535,aquamarine:8388564,azure:15794175,beige:16119260,bisque:16770244,black:0,blanchedalmond:16772045,blue:255,blueviolet:9055202,brown:10824234,burlywood:14596231,cadetblue:6266528,chartreuse:8388352,chocolate:13789470,coral:16744272,cornflowerblue:6591981,cornsilk:16775388,crimson:14423100,cyan:65535,darkblue:139,darkcyan:35723,darkgoldenrod:12092939,darkgray:11119017,darkgreen:25600,darkgrey:11119017,darkkhaki:12433259,darkmagenta:9109643,darkolivegreen:5597999,darkorange:16747520,darkorchid:10040012,darkred:9109504,darksalmon:15308410,darkseagreen:9419919,darkslateblue:4734347,darkslategray:3100495,darkslategrey:3100495,darkturquoise:52945,darkviolet:9699539,deeppink:16716947,deepskyblue:49151,dimgray:6908265,dimgrey:6908265,dodgerblue:2003199,firebrick:11674146,floralwhite:16775920,forestgreen:2263842,fuchsia:16711935,gainsboro:14474460,ghostwhite:16316671,gold:16766720,goldenrod:14329120,gray:8421504,green:32768,greenyellow:11403055,grey:8421504,honeydew:15794160,hotpink:16738740,indianred:13458524,indigo:4915330,ivory:16777200,khaki:15787660,lavender:15132410,lavenderblush:16773365,lawngreen:8190976,lemonchiffon:16775885,lightblue:11393254,lightcoral:15761536,lightcyan:14745599,lightgoldenrodyellow:16448210,lightgray:13882323,lightgreen:9498256,lightgrey:13882323,lightpink:16758465,lightsalmon:16752762,lightseagreen:2142890,lightskyblue:8900346,lightslategray:7833753,lightslategrey:7833753,lightsteelblue:11584734,lightyellow:16777184,lime:65280,limegreen:3329330,linen:16445670,magenta:16711935,maroon:8388608,mediumaquamarine:6737322,mediumblue:205,mediumorchid:12211667,mediumpurple:9662683,mediumseagreen:3978097,mediumslateblue:8087790,mediumspringgreen:64154,mediumturquoise:4772300,mediumvioletred:13047173,midnightblue:1644912,mintcream:16121850,mistyrose:16770273,moccasin:16770229,navajowhite:16768685,navy:128,oldlace:16643558,olive:8421376,olivedrab:7048739,orange:16753920,orangered:16729344,orchid:14315734,palegoldenrod:15657130,palegreen:10025880,paleturquoise:11529966,palevioletred:14381203,papayawhip:16773077,peachpuff:16767673,peru:13468991,pink:16761035,plum:14524637,powderblue:11591910,purple:8388736,rebeccapurple:6697881,red:16711680,rosybrown:12357519,royalblue:4286945,saddlebrown:9127187,salmon:16416882,sandybrown:16032864,seagreen:3050327,seashell:16774638,sienna:10506797,silver:12632256,skyblue:8900331,slateblue:6970061,slategray:7372944,slategrey:7372944,snow:16775930,springgreen:65407,steelblue:4620980,tan:13808780,teal:32896,thistle:14204888,tomato:16737095,turquoise:4251856,violet:15631086,wheat:16113331,white:16777215,whitesmoke:16119285,yellow:16776960,yellowgreen:10145074};function b(){return this.rgb().formatHex()}function m(){return this.rgb().formatRgb()}function y(t){var e,r;return t=(t+"").trim().toLowerCase(),(e=u.exec(t))?(r=e[1].length,e=parseInt(e[1],16),6===r?w(e):3===r?new M(e>>8&15|e>>4&240,e>>4&15|240&e,(15&e)<<4|15&e,1):8===r?k(e>>24&255,e>>16&255,e>>8&255,(255&e)/255):4===r?k(e>>12&15|e>>8&240,e>>8&15|e>>4&240,e>>4&15|240&e,((15&e)<<4|15&e)/255):null):(e=l.exec(t))?new M(e[1],e[2],e[3],1):(e=h.exec(t))?new M(255*e[1]/100,255*e[2]/100,255*e[3]/100,1):(e=c.exec(t))?k(e[1],e[2],e[3],e[4]):(e=g.exec(t))?k(255*e[1]/100,255*e[2]/100,255*e[3]/100,e[4]):(e=d.exec(t))?E(e[1],e[2]/100,e[3]/100,1):(e=f.exec(t))?E(e[1],e[2]/100,e[3]/100,e[4]):p.hasOwnProperty(t)?w(p[t]):"transparent"===t?new M(NaN,NaN,NaN,0):null}function w(t){return new M(t>>16&255,t>>8&255,255&t,1)}function k(t,e,r,n){return n<=0&&(t=e=r=NaN),new M(t,e,r,n)}function v(t){return t instanceof r||(t=y(t)),t?new M((t=t.rgb()).r,t.g,t.b,t.opacity):new M}function N(t,e,r,n){return 1===arguments.length?v(t):new M(t,e,r,null==n?1:n)}function M(t,e,r,n){this.r=+t,this.g=+e,this.b=+r,this.opacity=+n}function x(){return"#"+q(this.r)+q(this.g)+q(this.b)}function R(){var t=this.opacity;return(1===(t=isNaN(t)?1:Math.max(0,Math.min(1,t)))?"rgb(":"rgba(")+Math.max(0,Math.min(255,Math.round(this.r)||0))+", "+Math.max(0,Math.min(255,Math.round(this.g)||0))+", "+Math.max(0,Math.min(255,Math.round(this.b)||0))+(1===t?")":", "+t+")")}function q(t){return((t=Math.max(0,Math.min(255,Math.round(t)||0)))<16?"0":"")+t.toString(16)}function E(t,e,r,n){return n<=0?t=e=r=NaN:r<=0||r>=1?t=e=NaN:e<=0&&(t=NaN),new j(t,e,r,n)}function $(t){if(t instanceof j)return new j(t.h,t.s,t.l,t.opacity);if(t instanceof r||(t=y(t)),!t)return new j;if(t instanceof j)return t;var e=(t=t.rgb()).r/255,n=t.g/255,a=t.b/255,i=Math.min(e,n,a),o=Math.max(e,n,a),s=NaN,u=o-i,l=(o+i)/2;return u?(s=e===o?(n-a)/u+6*(n<a):n===o?(a-e)/u+2:(e-n)/u+4,u/=l<.5?o+i:2-o-i,s*=60):u=l>0&&l<1?0:s,new j(s,u,l,t.opacity)}function H(t,e,r,n){return 1===arguments.length?$(t):new j(t,e,r,null==n?1:n)}function j(t,e,r,n){this.h=+t,this.s=+e,this.l=+r,this.opacity=+n}function A(t,e,r){return 255*(t<60?e+(r-e)*t/60:t<180?r:t<240?e+(r-e)*(240-t)/60:e)}function O(t,e,r,n,a){var i=t*t,o=i*t;return((1-3*t+3*i-o)*e+(4-6*i+3*o)*r+(1+3*t+3*i-3*o)*n+o*a)/6}function S(t){var e=t.length-1;return function(r){var n=r<=0?r=0:r>=1?(r=1,e-1):Math.floor(r*e),a=t[n],i=t[n+1],o=n>0?t[n-1]:2*a-i,s=n<e-1?t[n+2]:2*i-a;return O((r-n/e)*e,o,a,i,s)}}function C(t){var e=t.length;return function(r){var n=Math.floor(((r%=1)<0?++r:r)*e),a=t[(n+e-1)%e],i=t[n%e],o=t[(n+1)%e],s=t[(n+2)%e];return O((r-n/e)*e,a,i,o,s)}}function z(t){return function(){return t}}function I(t,e){return function(r){return t+r*e}}function L(t,e){var r=e-t;return r?I(t,r>180||r<-180?r-360*Math.round(r/360):r):z(isNaN(t)?e:t)}function P(t){return 1==(t=+t)?B:function(e,r){return r-e?function(t,e,r){return t=Math.pow(t,r),e=Math.pow(e,r)-t,r=1/r,function(n){return Math.pow(t+n*e,r)}}(e,r,t):z(isNaN(e)?r:e)}}function B(t,e){var r=e-t;return r?I(t,r):z(isNaN(t)?e:t)}t(r,y,{copy:function(t){return Object.assign(new this.constructor,this,t)},displayable:function(){return this.rgb().displayable()},hex:b,formatHex:b,formatHsl:function(){return $(this).formatHsl()},formatRgb:m,toString:m}),t(M,N,e(r,{brighter:function(t){return t=null==t?1/.7:Math.pow(1/.7,t),new M(this.r*t,this.g*t,this.b*t,this.opacity)},darker:function(t){return t=null==t?.7:Math.pow(.7,t),new M(this.r*t,this.g*t,this.b*t,this.opacity)},rgb:function(){return this},displayable:function(){return-.5<=this.r&&this.r<255.5&&-.5<=this.g&&this.g<255.5&&-.5<=this.b&&this.b<255.5&&0<=this.opacity&&this.opacity<=1},hex:x,formatHex:x,formatRgb:R,toString:R})),t(j,H,e(r,{brighter:function(t){return t=null==t?1/.7:Math.pow(1/.7,t),new j(this.h,this.s,this.l*t,this.opacity)},darker:function(t){return t=null==t?.7:Math.pow(.7,t),new j(this.h,this.s,this.l*t,this.opacity)},rgb:function(){var t=this.h%360+360*(this.h<0),e=isNaN(t)||isNaN(this.s)?0:this.s,r=this.l,n=r+(r<.5?r:1-r)*e,a=2*r-n;return new M(A(t>=240?t-240:t+120,a,n),A(t,a,n),A(t<120?t+240:t-120,a,n),this.opacity)},displayable:function(){return(0<=this.s&&this.s<=1||isNaN(this.s))&&0<=this.l&&this.l<=1&&0<=this.opacity&&this.opacity<=1},formatHsl:function(){var t=this.opacity;return(1===(t=isNaN(t)?1:Math.max(0,Math.min(1,t)))?"hsl(":"hsla(")+(this.h||0)+", "+100*(this.s||0)+"%, "+100*(this.l||0)+"%"+(1===t?")":", "+t+")")}}));var D=function t(e){var r=P(e);function n(t,e){var n=r((t=N(t)).r,(e=N(e)).r),a=r(t.g,e.g),i=r(t.b,e.b),o=B(t.opacity,e.opacity);return function(e){return t.r=n(e),t.g=a(e),t.b=i(e),t.opacity=o(e),t+""}}return n.gamma=t,n}(1);function F(t){return function(e){var r,n,a=e.length,i=new Array(a),o=new Array(a),s=new Array(a);for(r=0;r<a;++r)n=N(e[r]),i[r]=n.r||0,o[r]=n.g||0,s[r]=n.b||0;return i=t(i),o=t(o),s=t(s),n.opacity=1,function(t){return n.r=i(t),n.g=o(t),n.b=s(t),n+""}}}var G=F(S),J=F(C);export{r as C,M as R,z as a,H as b,y as c,t as d,e,S as f,C as g,L as h,D as i,G as j,J as k,a as l,n as m,B as n,N as o,v as r};
//# sourceMappingURL=rgb-50db7803.js.map