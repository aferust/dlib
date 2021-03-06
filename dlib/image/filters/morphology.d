/*
Copyright (c) 2011-2019 Timur Gafarov

Boost Software License - Version 1.0 - August 17th, 2003

Permission is hereby granted, free of charge, to any person or organization
obtaining a copy of the software and accompanying documentation covered by
this license (the "Software") to use, reproduce, display, distribute,
execute, and transmit the Software, and to prepare derivative works of the
Software, and to permit third-parties to whom the Software is furnished to
do so, all subject to the following:

The copyright notices in the Software and this entire statement, including
the above license grant, this restriction and the following disclaimer,
must be included in all copies of the Software, in whole or in part, and
all derivative works of the Software, unless such copies or derivative
works are solely in the form of machine-executable object code generated by
a source language processor.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE, TITLE AND NON-INFRINGEMENT. IN NO EVENT
SHALL THE COPYRIGHT HOLDERS OR ANYONE DISTRIBUTING THE SOFTWARE BE LIABLE
FOR ANY DAMAGES OR OTHER LIABILITY, WHETHER IN CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.
*/

module dlib.image.filters.morphology;

private
{
    import dlib.image.color;
    import dlib.image.image;
    import dlib.image.arithmetics;
}

enum MorphOperation
{
    Dilate,
    Erode
}

// TODO:
// add support for other structuring elements
// other than box (disk, diamond, etc)
SuperImage morphOp(MorphOperation op) (SuperImage img, SuperImage outp)
in
{
    assert (img.data.length);
}
body
{
    SuperImage res;
    if (outp)
        res = outp;
    else
        res = img.dup;

    uint kw = 3, kh = 3;

    foreach(y; 0..img.height)
    foreach(x; 0..img.width)
    {
        static if (op == MorphOperation.Dilate)
        {
            Color4f resc = Color4f(0, 0, 0, 1);
        }
        static if (op == MorphOperation.Erode)
        {
            Color4f resc = img[x, y];
        }

        foreach(ky; 0..kh)
        foreach(kx; 0..kw)
        {
            int iy = y + (ky - kh/2);
            int ix = x + (kx - kw/2);

            // Extend
            if (ix < 0) ix = 0;
            if (ix >= img.width) ix = img.width - 1;
            if (iy < 0) iy = 0;
            if (iy >= img.height) iy = img.height - 1;

            // TODO:
            // Wrap

            auto pix = img[ix, iy];

            static if (op == MorphOperation.Dilate)
            {
                if (pix > resc)
                    resc = pix;
            }
            static if (op == MorphOperation.Erode)
            {
                if (pix < resc)
                    resc = pix;
            }
        }

        res[x, y] = resc;
    }

    return res;
}

SuperImage morph(MorphOperation op) (SuperImage img)
{
    return morphOp!(op)(img, null);
}

alias dilate = morph!(MorphOperation.Dilate);
alias erode = morph!(MorphOperation.Erode);

SuperImage open(SuperImage img)
{
    return dilate(erode(img));
}

SuperImage close(SuperImage img)
{
    return erode(dilate(img));
}

SuperImage gradient(SuperImage img)
{
    return subtract(dilate(img), erode(img));
}

SuperImage topHatWhite(SuperImage img)
{
    return subtract(img, open(img));
}

SuperImage topHatBlack(SuperImage img)
{
    return subtract(img, close(img));
}

// GC-free overloads:
SuperImage open(SuperImage img, SuperImage outp)
{
    if (outp is null)
        outp = img.dup;
    auto outp2 = outp.dup;

    auto e = morphOp!(MorphOperation.Erode)(img, outp2);
    auto d = morphOp!(MorphOperation.Dilate)(outp2, outp);
    outp2.free();
    return d;
}

SuperImage close(SuperImage img, SuperImage outp)
{
    if (outp is null)
        outp = img.dup;
    auto outp2 = outp.dup;

    auto d = morphOp!(MorphOperation.Dilate)(img, outp2);
    auto e = morphOp!(MorphOperation.Erode)(outp2, outp);
    outp2.free();
    return e;
}

SuperImage gradient(SuperImage img, SuperImage outp)
{
    if (outp is null)
        outp = img.dup;
    auto outp2 = outp.dup;

    auto d = morphOp!(MorphOperation.Dilate)(img, outp2);
    auto e = morphOp!(MorphOperation.Erode)(img, outp);
    auto s = subtract(d, e, outp);
    outp2.free();
    return s;
}

SuperImage topHatWhite(SuperImage img, SuperImage outp)
{
    if (outp is null)
        outp = img.dup;
    auto o = open(img, outp);
    auto s = subtract(img, o, outp);
    return s;
}

SuperImage topHatBlack(SuperImage img, SuperImage outp)
{
    if (outp is null)
        outp = img.dup;
    auto o = close(img, outp);
    auto s = subtract(img, o, outp);
    return s;
}
