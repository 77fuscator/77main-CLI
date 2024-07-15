using geniussolution;
using geniussolution.Obfuscator;
using System;
using System.IO;

namespace geniussolution_CLI
{
    internal class Program
    {
        private static void Main(string[] args)
        {
            Directory.CreateDirectory("temp");
            if (!_77F.Obfuscate("temp", args[0], new ObfuscationSettings(), out string err))
            {
                Console.WriteLine("ERR: " + err);
                return;
            }

            File.Delete("out.lua");
            File.Move("temp/out.lua", "out.lua");
            Directory.Delete("temp", true);
            Console.WriteLine("Done!");
        }
    }
}