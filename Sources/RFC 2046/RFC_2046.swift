// ===----------------------------------------------------------------------===//
//
// This source file is part of the swift-rfc-2046 open source project
//
// Copyright (c) 2025 Coen ten Thije Boonkkamp
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0
//
// ===----------------------------------------------------------------------===//

// RFC_2046.swift
// swift-rfc-2046

/// RFC 2046: Multipurpose Internet Mail Extensions (MIME) Part Two: Media Types
///
/// This module implements media types defined in RFC 2046, with focus on
/// multipart media types and body part structures.
///
/// ## Key Types
///
/// - ``Multipart``: Multipart message structure with boundary-separated parts
/// - ``Boundary``: Validated boundary delimiter string
/// - ``BodyPart``: Single part within a multipart message
///
/// ## Overview
///
/// RFC 2046 defines the structure of MIME media types, building on RFC 2045's
/// header definitions. This module provides:
///
/// - Multipart message construction and parsing
/// - Boundary validation per RFC 2046 Section 5.1.1
/// - Body part structure with typed headers
/// - All standard multipart subtypes (mixed, alternative, digest, parallel)
///
/// ## Example
///
/// ```swift
/// // Create a multipart/alternative message (text + HTML)
/// let textPart = RFC_2046.BodyPart(
///     contentType: .textPlainUTF8,
///     text: "Hello, World!"
/// )
///
/// let htmlPart = RFC_2046.BodyPart(
///     contentType: .textHTMLUTF8,
///     text: "<h1>Hello, World!</h1>"
/// )
///
/// let multipart = try RFC_2046.Multipart(
///     subtype: .alternative,
///     parts: [textPart, htmlPart],
///     boundary: "----=_Part_12345"
/// )
///
/// // Render the complete multipart body
/// let body = multipart.render()
/// ```
///
/// ## Media Types Defined
///
/// RFC 2046 establishes seven top-level media types:
///
/// **Discrete types** (content opaque to MIME):
/// - text (plain, html, etc.)
/// - image (jpeg, gif, png)
/// - audio (basic, mpeg)
/// - video (mpeg, mp4)
/// - application (octet-stream, json, etc.)
///
/// **Composite types** (MIME-aware):
/// - multipart (mixed, alternative, digest, parallel)
/// - message (rfc822, partial, external-body)
///
/// ## See Also
///
/// - [RFC 2046](https://www.rfc-editor.org/rfc/rfc2046)
/// - [RFC 2045](https://www.rfc-editor.org/rfc/rfc2045) - MIME Part One
/// - [RFC 2387](https://www.rfc-editor.org/rfc/rfc2387) - multipart/related
/// - [RFC 7578](https://www.rfc-editor.org/rfc/rfc7578) - multipart/form-data
public enum RFC_2046 {}
