package h2d.comp;

class Box extends Component {
	
	public function new(?layout,?parent) {
		super("box", parent);
		if( layout == null ) layout = h2d.css.Defs.Layout.Horizontal;
		addClass(":"+layout.getName().toLowerCase());
	}
	
	override function resizeRec( ctx : Context ) {
		var extX = extLeft();
		var extY = extTop();
		var ctx2 = new Context(0, 0);
		ctx2.measure = ctx.measure;
		if( ctx.measure ) {
			width = ctx.maxWidth;
			height = ctx.maxHeight;
			contentWidth = width - (extX + extRight());
			contentHeight = height - (extY + extBottom());
			if( style.width != null ) contentWidth = style.width;
			if( style.height != null ) contentHeight = style.height;
		} else {
			ctx2.xPos = ctx.xPos;
			ctx2.yPos = ctx.yPos;
			if( ctx2.xPos == null ) ctx2.xPos = 0;
			if( ctx2.yPos == null ) ctx2.yPos = 0;
			resize(ctx2);
		}
		switch( style.layout ) {
		case Horizontal:
			var lineHeight = 0.;
			var xPos = 0., yPos = 0., maxPos = 0.;
			var prev = null;
			for( c in components ) {
				if( ctx.measure ) {
					ctx2.maxWidth = contentWidth;
					ctx2.maxHeight = contentHeight - (yPos + lineHeight + style.verticalSpacing);
					c.resizeRec(ctx2);
					var next = xPos + c.width;
					if( prev != null ) next += style.horizontalSpacing;
					if( xPos > 0 && next > contentWidth ) {
						yPos += lineHeight + style.verticalSpacing;
						xPos = c.width;
						lineHeight = c.height;
					} else {
						xPos = next;
						if( c.height > lineHeight ) lineHeight = c.height;
					}
					if( xPos > maxPos ) maxPos = xPos;
				} else {
					var next = xPos + c.width;
					if( xPos > 0 && next > contentWidth ) {
						yPos += lineHeight + style.verticalSpacing;
						xPos = 0;
						lineHeight = c.height;
					} else {
						if( c.height > lineHeight ) lineHeight = c.height;
					}
					ctx2.xPos = xPos;
					ctx2.yPos = yPos;
					c.resizeRec(ctx2);
					xPos += c.width + style.horizontalSpacing;
				}
				prev = c;
			}
			if( ctx.measure && style.dock == null ) {
				if( maxPos < contentWidth && style.width == null ) contentWidth = maxPos;
				if( yPos + lineHeight < contentHeight && style.height == null ) contentHeight = yPos + lineHeight;
			}
		case Vertical:
			var colWidth = 0.;
			var xPos = 0., yPos = 0., maxPos = 0.;
			var prev = null;
			for( c in components ) {
				if( ctx.measure ) {
					ctx2.maxWidth = ctx.maxWidth - (xPos + colWidth + style.horizontalSpacing);
					ctx2.maxHeight = contentHeight;
					c.resizeRec(ctx2);
					var next = yPos + c.height;
					if( prev != null ) next += style.verticalSpacing;
					if( yPos > 0 && next > contentHeight ) {
						xPos += colWidth + style.horizontalSpacing;
						yPos = c.height;
						colWidth = c.width;
					} else {
						yPos = next;
						if( c.width > colWidth ) colWidth = c.width;
					}
					if( yPos > maxPos ) maxPos = yPos;
				} else {
					var next = yPos + c.height;
					if( yPos > 0 && next > contentHeight ) {
						xPos += colWidth + style.horizontalSpacing;
						yPos = 0;
						colWidth = c.width;
					} else {
						if( c.width > colWidth ) colWidth = c.width;
					}
					ctx2.xPos = xPos;
					ctx2.yPos = yPos;
					c.resizeRec(ctx2);
					yPos += c.height + style.verticalSpacing;
				}
				prev = c;
			}
			if( ctx.measure && style.dock == null ) {
				if( xPos + colWidth < contentWidth && style.width == null ) contentWidth = xPos + colWidth;
				if( maxPos < contentHeight && style.height == null ) contentHeight = maxPos;
			}
		case Absolute:
			ctx2.xPos = null;
			ctx2.yPos = null;
			if( ctx.measure ) {
				ctx2.maxWidth = contentWidth;
				ctx2.maxHeight = contentHeight;
			}
			for( c in components )
				c.resizeRec(ctx2);
		case Dock:
			ctx2.xPos = 0;
			ctx2.yPos = 0;
			var xPos = 0., yPos = 0., w = contentWidth, h = contentHeight;
			if( ctx.measure ) {
				for( c in components ) {
					ctx2.maxWidth = w;
					ctx2.maxHeight = h;
					c.resizeRec(ctx2);
					var d = c.style.dock;
					if( d == null ) d = Full;
					switch( d ) {
					case Left, Right:
						w -= c.width;
					case Top, Bottom:
						h -= c.height;
					case Full:
					}
					if( w < 0 ) w = 0;
					if( h < 0 ) h = 0;
				}
			} else {
				for( c in components ) {
					ctx2.maxWidth = w;
					ctx2.maxHeight = h;
					var d = c.style.dock;
					if( d == null ) d = Full;
					ctx2.xPos = xPos;
					ctx2.yPos = yPos;
					switch( d ) {
					case Left, Top:
					case Right:
						ctx2.xPos += w - c.width;
					case Bottom:
						ctx2.yPos += h - c.height;
					case Full:
						ctx2.xPos += Std.int((w - c.width) * 0.5);
						ctx2.yPos += Std.int((h - c.height) * 0.5);
					}
					c.resizeRec(ctx2);
					switch( d ) {
					case Left:
						w -= c.width;
						xPos += c.width;
					case Right:
						w -= c.width;
					case Top:
						h -= c.height;
						yPos += c.height;
					case Bottom:
						h -= c.height;
					case Full:
					}
					if( w < 0 ) w = 0;
					if( h < 0 ) h = 0;
				}
			}
		}
		if( ctx.measure ) {
			width = contentWidth + extX + extRight();
			height = contentHeight + extY + extBottom();
		}
	}
	
	
}