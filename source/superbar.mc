//! Copyright (C) 2018 Tomasz Korzec <tom@shmo.de>
//!
//! This program is free software: you can redistribute it and/or modify it
//! under the terms of the GNU General Public License as published by the Free
//! Software Foundation, either version 3 of the License, or (at your option)
//! any later version.
//!
//! This program is distributed in the hope that it will be useful, but WITHOUT
//! ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//! FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
//! more details.
//!
//! You should have received a copy of the GNU General Public License along
//! with this program. If not, see <http://www.gnu.org/licenses/>.


using Toybox.Graphics as Gfx;

var mask = [0xf, 0xf0, 0xf00, 0xf000, 0xf0000, 0xf00000, 0xf000000];

class superbar
{
   private var vals; // one value per float
   private var cols; // 7 values 0..15 per int
   private var minval;
   private var maxval;
   private var nval;
   private var x;
   private var y;
   private var dx;
   private var dy;
   private var pal;
   private var i=0;

   function reset()
   {
      nval = 0;
      minval = null;
      maxval = null;
      for(i=0; i<dx; i++)
      {
         vals[i]=0;
      }
      for(i=0; i<dx/7+1; i++)
      {
         cols[i]=0;
      }
   }


   function initialize(xx,yy,dxx,dyy,p)
   {
      x=xx;
      y=yy;
      dx=dxx;
      dy=dyy;
      vals = new[dx];
      cols = new[dx/7+1];
      reset();
      pal = p;
   }


   function addval(val,col)
   {
      if(minval==null)
      {
         minval = Math.floor(val).toNumber();
         maxval = Math.ceil(val).toNumber();
      }
      // move all values one to the left
      for( i=nval; i>=0; i--)
      {
         vals[i+1] = vals[i];
         //System.println(i+" "+(i+1)%7+" "+ ~mask[(i+1)%7]);
         cols[(i+1)/7] &= ~mask[(i+1)%7]; // delete i+1 entry
         cols[(i+1)/7] |= ((cols[i/7] & mask[i%7]) >> (4*(i%7))) << (4*((i+1)%7)) ;
      }
      if (val==null || val==NaN)
      {
         val = vals[1];
      }
      if( (col == null) || (col < 0) || (col>=pal.size()) )
      {
         col = (cols[0] & mask[1])>>4;
      }
      vals[0] = val;
      cols[0] &= ~mask[0];
      cols[0] |= col;
      if (nval<dx-2)
      {
         nval++;
      }
      if (val<minval)
      {
         minval = Math.floor(val).toNumber();
      }
      if (val>maxval)
      {
         maxval = Math.ceil(val).toNumber();
      }
   }

   function plot(dc)
   {
      dc.setClip(x,y,dx,dy);
      TachoView.setCol(dc,Gfx.COLOR_WHITE,Gfx.COLOR_BLACK);

      dc.drawRectangle(x,y,dx,dy);
      if((minval != null) && (maxval != minval))
      {
         dc.setClip(x+1,y+1,dx-2,dy-2);
         for(i=0; i<nval; i++)
         {
            //System.println(i+" "+i/7+" "+i%7+" "+(cols[i/7] & mask[i%7]) >> (4*(i%7)));

            dc.setColor(pal[((cols[i/7] & mask[i%7]) >> (4*(i%7))) % pal.size()],Gfx.COLOR_WHITE);
            dc.drawLine(x+dx-i,y+dy,x+dx-i,y+dy-(vals[i]-minval)*dy/(maxval-minval));
         }
         TachoView.setCol(dc,Gfx.COLOR_WHITE,Gfx.COLOR_BLACK);
         dc.drawText(x+1, y , Gfx.FONT_XTINY, maxval, Gfx.TEXT_JUSTIFY_LEFT);
         dc.drawText(x+1, y+dy-15, Gfx.FONT_XTINY, minval, Gfx.TEXT_JUSTIFY_LEFT);
      }
      dc.clearClip();
   }
}