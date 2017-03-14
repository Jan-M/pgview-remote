==========
PGView Web
==========

Local testing
=============

Run Spilo locally
-----------------

.. code-block::bash

  docker run -p 8080:8080 registry.opensource.zalan.do/acid/spiloprivate-9.6:1.2-p1

Run locally
-----------

Run Python flask backend app:

.. code-block::bash

  python3 -m pgview_web


Hot update of Javascript/riot
-----------------------------

In app folder run:

.. code-block:: bash

  npm start

License
=======

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see http://www.gnu.org/licenses/.
